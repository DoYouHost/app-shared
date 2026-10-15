# /// script
# requires-python = ">=3.11"
# dependencies = ["google-api-python-client>=2.100", "google-auth>=2.20"]
# ///
"""Google Play publishing: list the tracks, or release bundles to internal testing.

  tracks                        list every track and the releases on it
  internal [--dry-run] AAB...   upload the bundles and release each one to
                                internal testing, all in one committed edit

A bundle whose versionCode is already on its track is skipped, so a re-run after
a failure finishes the job instead of tripping over "version code already used".

What differs per application — its applicationId, where its service-account
key lives, which versionCode band goes to which track — is `tool/play.toml` in
the application (`--config` points elsewhere). The key lives outside the repo;
PLAY_SA_KEY overrides its path. Run as `dart run app_guards:play`, which goes
through uv for the dependencies declared above.

usage: dart run app_guards:play tracks | internal [--dry-run] AAB...
"""

import argparse
import os
import socket
import sys
import tomllib
import zipfile
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload



# aab_versions.py ships next to this script.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from aab_versions import bundle_versions  # noqa: E402

SCOPE = "https://www.googleapis.com/auth/androidpublisher"

# Filled from the application's configuration by `load_config`.
PACKAGE = ""
KEY = Path()
# (lowest versionCode, track), highest first: a bundle goes to the first band
# its code reaches. bambuddy's watch band starts a billion up, so the code baked
# into a bundle says which form factor it is — more reliably than the order or
# the name of the files handed in.
BANDS: list[tuple[int, str]] = []


def load_config(path: str) -> None:
    """The application's half: see the `tool/play.toml` files."""
    global PACKAGE, KEY, BANDS
    with open(path, "rb") as f:
        config = tomllib.load(f)
    PACKAGE = config["package"]
    # Not `environ.get(..., config["key"])`: the default is evaluated first, so
    # a configuration that leaves the key to PLAY_SA_KEY would fail on it.
    key = os.environ.get("PLAY_SA_KEY") or config.get("key")
    if not key:
        sys.exit("No service-account key: set `key` in the configuration or PLAY_SA_KEY.")
    KEY = Path(key).expanduser()
    BANDS = sorted(
        ((band["from"], band["track"]) for band in config.get("bands", [])),
        reverse=True,
    )


def track_for(code: int) -> str:
    for lowest, track in BANDS:
        if code >= lowest:
            return track
    sys.exit(f"versionCode {code} is below every band in the configuration")


# Play answers a bundle upload only once it has processed it, which can outlast
# the client's 60 s socket default; fastlane's supply waits 300 s for the same reason.
socket.setdefaulttimeout(300)

# Every call backs off and retries on 5xx/429 (googleapiclient doubles the wait,
# ~2 min in all): Play's API answers 503 often enough that one miss used to
# fail a whole `ship-dev` after the builds had already been paid for.
RETRIES = 6


def list_tracks(edits, edit_id):
    tracks = edits.tracks().list(packageName=PACKAGE, editId=edit_id).execute(num_retries=RETRIES)
    for track in tracks.get("tracks", []):
        # A track with no releases still gets a line: its name is what we need.
        for release in track.get("releases") or [{}]:
            codes = ",".join(release.get("versionCodes", [])) or "-"
            print(
                f"{track['track']:<22} {release.get('status', '-'):<12}"
                f" {release.get('name', '-'):<22} {codes}"
            )


def read_bundles(paths):
    """(path, versionName, versionCode, track) per bundle, checked as one pair."""
    bundles = []
    for path in paths:
        try:
            name, code = bundle_versions(path)
        except (OSError, zipfile.BadZipFile, KeyError, ValueError, StopIteration) as err:
            sys.exit(f"{path}: cannot read the bundle ({err})")
        if name is None or code is None:
            sys.exit(f"{path}: manifest carries no version")
        track = track_for(int(code))
        bundles.append((path, name, int(code), track))

    # Every form factor is built from one version, so a mismatch means one file is
    # a leftover from an earlier build, not the set this run produced.
    if len({name for _, name, _, _ in bundles}) != 1:
        sys.exit("Bundles carry different versions:\n" + "\n".join(
            f"  {path}  {name}  {code}" for path, name, code, _ in bundles))
    if len({track for *_, track in bundles}) != len(bundles):
        sys.exit("Two bundles would go to the same track.")
    return bundles


def release_internal(edits, edit_id, bundles, dry_run):
    """Stage every bundle on its internal track; True when the edit needs a commit."""
    on_track = {
        track["track"]: {
            int(code) for release in track.get("releases", [])
            for code in release.get("versionCodes", [])
        }
        for track in edits.tracks().list(packageName=PACKAGE, editId=edit_id)
        .execute(num_retries=RETRIES).get("tracks", [])
    }
    # Bundles already in the app's library — uploaded by a run that died before
    # its commit, or by hand in the Console — only need assigning to the track.
    uploaded = {
        bundle["versionCode"] for bundle in
        edits.bundles().list(packageName=PACKAGE, editId=edit_id).execute(num_retries=RETRIES).get("bundles", [])
    }

    changed = False
    for path, name, code, track in bundles:
        release_name = f"{code} ({name})"
        if code in on_track.get(track, set()):
            print(f"{track}: {release_name} already there, skipping")
            continue
        if dry_run:
            action = "assign" if code in uploaded else "upload"
            print(f"{track}: would {action} {release_name} from {path}")
            continue
        if code not in uploaded:
            print(f"{track}: uploading {path} ({release_name})")
            edits.bundles().upload(
                packageName=PACKAGE,
                editId=edit_id,
                media_body=MediaFileUpload(path, mimetype="application/octet-stream", resumable=True),
            ).execute(num_retries=RETRIES)
        edits.tracks().update(
            packageName=PACKAGE,
            editId=edit_id,
            track=track,
            body={
                "track": track,
                "releases": [{"name": release_name, "versionCodes": [str(code)], "status": "completed"}],
            },
        ).execute(num_retries=RETRIES)
        print(f"{track}: {release_name} staged")
        changed = True
    return changed


def commit_edit(edits, edit_id):
    """Commits in whichever of Play's two states the Console is in.

    Each state refuses the other's commit with a 400: while changes sit unsent
    (a rejected Wear build left them there) only a held commit is accepted, and
    while they are in review the flag "must not be set". The held one goes
    first, so unsent changes are never sent from here; the plain one carries
    only internal tracks, which Google publishes without a review.
    """
    try:
        edits.commit(
            packageName=PACKAGE, editId=edit_id, changesNotSentForReview=True
        ).execute(num_retries=RETRIES)
    except HttpError as e:
        if e.status_code != 400 or "must not be set" not in str(e.reason):
            raise
        edits.commit(packageName=PACKAGE, editId=edit_id).execute(num_retries=RETRIES)


def main():
    parser = argparse.ArgumentParser(description="Google Play publishing.")
    parser.add_argument("--config", default="tool/play.toml",
                        help="the application's configuration (default: tool/play.toml)")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("tracks", help="list every track and the releases on it")
    internal = commands.add_parser("internal", help="release bundles to internal testing")
    internal.add_argument("--dry-run", action="store_true", help="read and report, change nothing")
    internal.add_argument("bundles", nargs="+", metavar="AAB")
    args = parser.parse_args()
    load_config(args.config)

    # Read before touching the network, so a missing or mismatched bundle
    # costs nothing and leaves no edit behind.
    bundles = read_bundles(args.bundles) if args.command == "internal" else []
    if not KEY.is_file():
        sys.exit(f"No service-account key at {KEY} (set PLAY_SA_KEY to override).")
    creds = service_account.Credentials.from_service_account_file(str(KEY), scopes=[SCOPE])
    edits = build("androidpublisher", "v3", credentials=creds, cache_discovery=False).edits()

    try:
        edit_id = edits.insert(packageName=PACKAGE, body={}).execute(num_retries=RETRIES)["id"]
        committed = False
        try:
            if args.command == "tracks":
                list_tracks(edits, edit_id)
            elif release_internal(edits, edit_id, bundles, args.dry_run):
                commit_edit(edits, edit_id)
                committed = True
                print("Released to internal testing.")
        finally:
            if not committed:
                edits.delete(packageName=PACKAGE, editId=edit_id).execute(num_retries=RETRIES)
    except HttpError as e:
        # A fresh Play Console grant can take a while to reach the API, so a 403
        # right after setup is not necessarily a wrong permission.
        sys.exit(f"Play API {e.status_code}: {e.reason}")


if __name__ == "__main__":
    main()
