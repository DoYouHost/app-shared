#!/usr/bin/env python3
"""Check the store screenshots a `tool/play.toml` lists against Play's limits.

The `[screenshots]` table names, per device type, the files that go to the
listing, in order. Play's limits ("Add preview assets" in the Play Console
help): at most 8 per device type; 320 to 3840 px; the long side at most twice
the short one; a watch screenshot square and at least 384 px. PNG only, which
is what `adb exec-out screencap -p` writes.

usage: tool/store_images.py [CONFIG]   (default: tool/play.toml)

Prints the plan and exits 0 when every file passes; otherwise prints every
problem and exits 1. `dart run app_guards:play screenshots` runs the same check
before it opens an edit.
"""

import struct
import sys
import tomllib
from pathlib import Path

# The `[screenshots]` keys, and the Play image type each one fills.
IMAGE_TYPES = {
    "phone": "phoneScreenshots",
    "tablet7": "sevenInchScreenshots",
    "tablet10": "tenInchScreenshots",
    "wear": "wearScreenshots",
    "tv": "tvScreenshots",
}
PER_TYPE = 8


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    # IHDR: width and height are the two big-endian words at byte 16.
    return struct.unpack(">II", head[16:24])


def screenshot_plan(table, base):
    """({Play image type: [paths]}, [problems]) for a `[screenshots]` table.

    `language` is the listing's, not a device type. Paths are relative to
    [base], the application's root, as the bundles of `internal` are.
    """
    plan, problems = {}, []
    for key, names in table.items():
        if key == "language":
            continue
        kind = IMAGE_TYPES.get(key)
        if kind is None:
            problems.append(f"{key}: not a device type ({', '.join(IMAGE_TYPES)})")
            continue
        if len(names) > PER_TYPE:
            problems.append(f"{key}: {len(names)} screenshots, Play takes {PER_TYPE}")
        paths = []
        for name in names:
            path = base / name
            try:
                width, height = png_size(path)
            except (OSError, ValueError) as err:
                problems.append(f"{name}: {err}")
                continue
            short, long = sorted((width, height))
            if short < 320 or long > 3840:
                problems.append(f"{name}: {width}x{height}, Play takes 320-3840 px")
            if long > 2 * short:
                problems.append(f"{name}: {width}x{height}, the long side is over twice the short")
            if key == "wear" and (width != height or width < 384):
                problems.append(f"{name}: {width}x{height}, a watch screenshot is square, 384 px or more")
            paths.append(path)
        plan[kind] = paths
    if not plan and not problems:
        problems.append("[screenshots] names no device type")
    return plan, problems


def main():
    config = Path(sys.argv[1] if len(sys.argv) > 1 else "tool/play.toml")
    with open(config, "rb") as f:
        table = tomllib.load(f).get("screenshots")
    if not table:
        sys.exit(f"{config}: no [screenshots] table")
    plan, problems = screenshot_plan(table, Path.cwd())
    for problem in problems:
        print(problem)
    if problems:
        sys.exit(1)
    for kind, paths in plan.items():
        print(f"{kind}: {len(paths)}")


if __name__ == "__main__":
    main()
