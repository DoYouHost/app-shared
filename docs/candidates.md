# What else could live here

Measured across bambuddy-mobile and lubelogger-mobile in September 2026, while
extracting [`app_diagnostics`](../packages/app_diagnostics). Nothing below is
started; this is the evidence and the blocker for each, so the next round does
not have to re-measure.

The rule that decides all of them is the one `app_report_client` already
follows: a package takes what both applications mean identically, and requires
everything they mean differently as a parameter. Where that parameter list would
be longer than the code, the answer is no.

## 1. ~~lubelogger has not adopted `app_report_client` at all~~ — done in v0.3.0

lubelogger-mobile moved onto both packages together. The one thing it recorded
that `app_diagnostics` could not was a write's request body, which is now
`HttpProbeConfig.sampleRequests` (off by default, so bambuddy is unaffected).

## 2. ~~`dash_ui` — the design system~~ — done in v0.4.0

The brand is a `DashBrand` handed to `buildDashThemeData`, which registers the
resolved `DashTokens` as a theme extension. Each app keeps its brand, its
wordmark, and aliases (`accentGreen`, `accentGold`) for the generic `accent` and
`accentInk`, so no call site had to change. bambuddy also keeps its log-tagged
`dashAppBar` and `dashSaveAction`, which need `app_diagnostics`.

The contrast test is `dashContrastAudit`. Each app runs it on its own brand.
Running it on lubelogger's brand changed three things there, all on purpose:

- it takes bambuddy's muted inks, which were already fixed to reach 4.5:1;
- its light-theme gold ink moves from #9A6E12 (3.81:1) to #835E0F (4.92:1);
- its elevated and outlined buttons get the filled button's padding, so buttons
  side by side are the same height.

## 3. ~~`app_report_ui` — the report screen~~ — done in v0.5.0

Localization went into the package: 89 of the 95 strings the apps shared were
already word for word the same. The few that differed were claims about what
each app's log contains, and those stay with the app as `ReportConsent`, along
with the two entry-point labels. The rest of `ReportBindings` is the app's
recorder and sender, its root navigator, where "home" is, and a log file
prefix.

The two copies had moved apart, so the package takes the better half of each.
From bambuddy: a request's ticket is bought on the first keystroke, a send
cannot be tapped twice while facts load, a salvaged session outlives `reset`,
and small text and icons use ink colors rather than the vivid fills. From
lubelogger: a countdown seen from another tab names its report, the review
lists the session header's facts, a background isolate's records say so, and
the screen is capped on a tablet.

`app_diagnostics` has to be at v0.3.0 in any app that uses this package,
because the package pins that ref. For bambuddy that brings request-body
sampling, which stays off by default.

## 4. `wear_ui` — the round-face layout

Self-contained, and verified so: of `wear_geometry`, `wear_shape`, `wear_face`,
`wear_face_curve`, `wear_scroll_view`, `wear_scroll_indicator`, `wear_toast`,
`wear_screen`, `wear_spinner` and `wear_header`, only `wear_toast` and
`wear_confirm_dialog` reach outside their own directory (one localized label
each), and `wear_shape` uses `PlatformQuery`.

The inscribed-rectangle geometry is the hardest-won code in either repository:
Google Play rejected the build that lacked it, because the first list row and
the setup screen's Save button were cut by the bezel.

Blocker: there is no second watch app. This is a bet, and the value until it pays
off is only that the next one does not start by rediscovering that `SafeArea`
resolves to zero on a round display.

## 5. ~~Small utilities~~ — done in v0.6.0, as `app_util`

One package, because each of these is too small to carry its own pubspec. Not
everything in the list was the same in both apps once it was read closely, so
the package took less than the table promised:

- **JSON.** The coercers, the tolerant list and object parsers, and the calendar
  date moved. `dateTimeFromJson` and `instantToJson` stayed in bambuddy: they
  read a zoneless timestamp as UTC, which is how bambuddy's server stores time
  and not how LubeLogger's does. lubelogger dropped a `_toInt`/`_toDouble` pair
  from each of nine models. Its list parser now also survives a record whose
  factory throws, and logs `parse_drop` where it used to log `records_dropped`.
- **The server address.** The scheme a bare host gets is a parameter
  (`http` for bambuddy, `https` for lubelogger), and so is lubelogger's trailing
  `/api`. `baseUrlFromReached` was identical and moved as it was.
- **`mapDioException`.** Only the classification moved, as `DioFailure`. The
  codes and exception classes are each app's own, so each app now has a switch
  over the classification. The package names every `DioExceptionType`, so it
  needs dio 5.10+, which moved bambuddy's lock from 5.9.2.
- **The demo adapter.** It takes the backend's `handle` and, for lubelogger, an
  `uploads` callback for multipart bodies. File responses came from bambuddy.
- **Numbers, bytes, text measurement.** lubelogger's forms read numbers through
  `parseUserDecimal`. That changes one thing on purpose: "1,000" is now refused
  as ambiguous instead of stored as 1. The settings screen shows `formatBytes`
  ("834 KB" where it said "834 kB"), and the dashboard measures with
  `textWidth`, which follows the reading direction.
- `PlatformQuery` and the hex colours have no lubelogger caller yet. They are
  here because `wear_ui` (item 4) would need the first.

## ~~A gap in this repository~~ — closed

CI now runs `dart format --output=none --set-exit-if-changed lib test` in every
package, next to analyze and test. `app_report_client` was reformatted in the
same change, and `.git-blame-ignore-revs` lists that commit.

Adding the gate turned up an older bug in the same loop. `set -e` does not apply
inside a subshell on the left of `||`, so each package's status was only its last
command's, and a failing `flutter analyze` passed as long as the tests passed.
Each step now records its own failure.

# Round two

Measured on 14 September 2026, after `app_util` v0.7.1, against bambuddy-mobile
and lubelogger-mobile on their `dev` branches. The rule is the same as in round
one.

Items 6, 7, 9 and 10 are done. What is left is the three ports under item 8,
and the two package moves item 6 deferred to a release after v0.9.0.

## 6. ~~`dash_kit` — the widgets that carry log tags~~ — done in v0.8.0

The same small widgets exist in three copies, not two, because `app_report_ui`
grew its own while it was extracted:

| what | lubelogger | bambuddy | `app_report_ui` |
|---|---|---|---|
| snack bar | calls `showSnackBar` directly (28 sites) | `DashSnack.snack()` | `ReportSnack.replaceSnack()` |
| destructive confirm | `TextButton` in `dangerInk` | `FilledButton` in `scheme.error` | `FilledButton` with `dashDangerButtonStyle` |
| content width cap | `ContentConstraint`, `kContentMaxWidth` | none | `MaxContentWidth` |
| bottom sheet | `showModalBottomSheet`, `kBottomSheetMaxWidth` (640) repeated at every call, which is Material 3's own default | `dashSheet`: a bottom `SafeArea` for Android 15 edge-to-edge | none |
| error and empty views | log `error_view` / `empty_view` records | `tonal`, `scrollable`, optional icon, `error.retry` tag | none |

So a user sees three different delete confirmations, and each application has
the better half of the error and empty views. bambuddy also has what lubelogger
lacks entirely: `DashLoading` / `DashSpinner`, `ButtonPair` (already on
`app_util`'s `textWidth`), `withSystemNavInset`, `SectionHeading`, and the
log-tagged `dashAppBar` / `dashSaveAction` that round one left in the app.

Why a new package and not `dash_ui`: `dash_ui` stays a leaf on purpose, so that
`app_diagnostics` is not forced to one ref through it. That argument is weaker
than it was. `app_report_ui` already depends on both, and both applications pin
the same refs. A `dash_kit` depending on `dash_ui` and `app_diagnostics` keeps
`dash_ui` a leaf, and `app_report_ui` drops `report_chrome.dart` for it.

The parameters stay short. The cancel label is
`MaterialLocalizations.cancelButtonLabel`, so the package needs no localization
of its own. The retry label is an argument. A sheet takes no width: Material 3
already caps it at 640 dp.

A render of lubelogger's record form in its sheet, with a 48 dp navigation bar
drawn edge to edge, puts Cancel and Save under the bar: `RecordFormScaffold`
pads for the keyboard (`viewInsets`) but not for the navigation bar. Its sheets
that are not forms carry their own `SafeArea`. Confirm it on a device with
gesture navigation (about 24 dp) before treating it as a shipped bug.

### What it became

`packages/dash_kit` exists with the decisions taken on rendered screens:

- **The confirmation** is one `confirmDialog`: both answers are filled buttons
  of equal width, dismiss on the left in a new `dashNeutralButtonStyle`, confirm
  on the right in `dashDangerButtonStyle` (or the accent when `destructive` is
  false). Both stretch to the taller one when a label wraps. When a single word
  cannot fit its half, the pair stacks full-width, dismiss above confirm:
  side by side, "Wiederherstellen" broke as "Wiederher|stellen" at normal text
  size on a 360 dp phone, and at a large system font every label broke. `id` is
  required, and the answer is recorded as lubelogger's `confirm` record. All
  three current confirmations change look; bambuddy's and `app_report_ui`'s
  keep their red.
- **The error view** is centred as in bambuddy, and with `scrollable: true` it
  can still be pulled, as in lubelogger. lubelogger's screens move their message
  from the upper part of the screen to the middle. `scrollable` stays off by
  default.
- **The sheet** is bambuddy's `dashSheet`; lubelogger's forms moving onto it is
  the fix above.
- `dashNeutralButtonStyle` lived in `dash_kit` at first, because `dash_kit`
  depends on `dash_ui` by tag. It sits beside `dashDangerButtonStyle` in
  `dash_ui` 0.3.1 now, where the rest of the button styles are.

Both applications pin `dash_kit` at v0.8.0, and `dash_ui` is theirs only
transitively now. In each of them `dash_theme.dart` re-exports `dash_kit` in
place of `dash_ui`, and the local copies are gone: bambuddy's eight widget
files, and the error, empty and confirmation views in both. What did not
survive a straight swap:

- **lubelogger, error views.** Its `AsyncErrorView` was always a list, and three
  sit directly under a `RefreshIndicator`: `garage_screen.dart`,
  `dashboard_screen.dart` and `vehicle/widgets/record_list.dart`. Each passes
  `scrollable: true` — without it pull-to-refresh stops working on the error
  screen, and nothing fails to compile to say so.
- **lubelogger, confirmations.** `confirmDelete` and `confirmRisky` stayed, as
  four-line wrappers that hand `confirmDialog` this app's title, message and
  labels, and `confirm.$what` as the id. Their call sites are untouched, and the
  ids are what they were, so logs already attached to issues still match.
- **lubelogger, sheets.** All nine `showModalBottomSheet` calls became
  `dashSheet`, which is what puts a form's buttons above the navigation bar.
  `kBottomSheetMaxWidth` went with them, being Material 3's own default.
- **lubelogger, width cap.** `ContentConstraint` is `MaxContentWidth`, which
  takes the width rather than defaulting to it.
- **bambuddy, confirmations.** Nothing: all 39 `confirmDialog` calls already
  pass an `id`.
- **bambuddy, redactor.** `surface` went into `ourKeys`, which lubelogger already
  had: without it, a server whose host is a word like `queue` masks that screen's
  name in the error and empty records.
- **Tests.** Four widget suites moved into `dash_kit` and one shrank to the
  `SheetSurface` cases that stay bambuddy's. Four dialog taps across the two
  applications now look for a `FilledButton`, which is what both answers are;
  lubelogger's tag-shape guard learned to read the id handed to `confirmDialog`,
  so `confirm.$what` is still checked where it is now written.

### What the v0.9.0 tag unblocked

`app_report_ui` could only reach `dash_kit` by tag, so `report_chrome.dart`
outlived the package that replaced it. It is gone in 0.1.2: `replaceSnack` is
`DashSnack.snack(replaceCurrent: true)`, `MaxContentWidth` is `dash_kit`'s own,
and `confirmDestructive` is `confirmDialog(destructive: true)` — which changes
three things in the report flow on purpose. Both answers are filled buttons of
equal width rather than a text cancel beside a filled confirm, the cancel label
comes from `MaterialLocalizations` (so the package's own `reportCancel` is gone
from five `.arb` files), and the answer is written to the log as a `confirm`
record, which the report screen's dialog never wrote before.

The refs this moves, all inside v0.10.0: `dash_kit` 0.1.2 names `dash_ui`
0.3.1, `app_report_ui` 0.1.2 names `dash_kit` and no longer names `dash_ui` at
all. Both applications then move their `dash_kit` and `app_report_ui` refs to
v0.10.0; everything else stays where it is.

Still open: `EmptyStateView` sits 48 dp under the app bar, as it did in both
apps, while the error view is now centred. Whether the empty view should centre
too is a design call that has not been made.

## 7. ~~`app_diagnostics`: device facts and the session store~~ — done in v0.9.0

- **`deviceEnvironment()` and `AppStart`** moved out of lubelogger, so bambuddy's
  header carries the UTC offset, the screen and its density, the text scale, dark
  mode, the device, SDK and emulator flag, and the uptime — none of which it had.
  The cost is `device_info_plus`, which the package now declares and bambuddy
  gains transitively. Two changes on the way: the screen is read through
  `WidgetsBinding.instance.platformDispatcher` rather than
  `PlatformDispatcher.instance` — the same view in the app, and the one a test
  can resize — and `uptime_s` is left out entirely until `main` stamps
  `AppStart.at`, rather than written as null. bambuddy's `main` now stamps it.
- **`readAppVersion()`** moved with them, since the header needs it. bambuddy's
  copy is gone; `package_info_plus` is declared as `>=8.0.0 <10.0.0`, because
  the two applications are a major apart and either spelling works.
- **`SharedPreferencesSessionStore`** replaces the adapter both applications had
  written over their own settings repository, and owns the
  `diagnostics_session` key and the rule that an empty id is no session.
  `loadSession` stays synchronous, as the port requires, so it still cannot
  refresh the snapshot itself: an isolate that did not write the id reloads its
  preferences first. Each repository keeps `loadDiagnosticsSession` for its
  other callers, now one line over `diagnosticsSessions`.

bambuddy's header contract test grew the three new keys, with the note that they
are additions a reader may ignore while the old ones must not move.

This goes out with the same **v0.9.0** as item 9, as `app_diagnostics` 0.3.0.
Everything that pins it moves too — `app_util` 0.2.2, `dash_kit` 0.1.1,
`app_report_ui` 0.1.1 and both applications — because one package resolved from
two refs is a version-solving error. Only `app_report_client` stays at v0.2.0.

## 8. ~~An API error package~~ — ports instead

`AppApiException`, `guard` and `guardOrNull` have the same skeleton in both
applications, and the classification under them is already `DioFailure`. The
codes are closed enums with different members (10 in lubelogger, 17 in
bambuddy), so sharing the rest needs generics and a parameter list longer than
the code. The answer is no.

The comparison did turn up gaps worth porting, and all three are ported:

- **to lubelogger:** `method` and `path` on the exception, so a failure names
  the request it belongs to. They reach the log through the `degraded` record,
  which already carried the cause and the status and now says which call the
  screen carried on without.
- **to bambuddy:** the `degraded` record in `guardOrNull`, without which a
  swallowed failure left no trace. `guardOrNullAllowingForbidden` writes it too,
  and `docs/diagnostics-log.md` describes it next to `action_failed` — the two
  are mirror images, one for a failure somebody was told about and one for a
  failure nobody was.
- **to bambuddy:** the demo host is skipped in `sessionSecrets`, as lubelogger
  does. `LogRedactor` replaces a known value as a substring, so in demo mode
  every `demo` outside a key protected by `ourKeys` became `[HOST]`. Low impact:
  demo mode is for store review only.

## 9. ~~Font licences in `dash_ui`~~ — done in v0.9.0

The font families stay declared by the applications, for the reason `dash_ui`
gives. The OFL texts moved into `dash_ui` as package assets, behind
`registerDashFontLicenses()`, which each application calls from `main` before
`runApp`. The registry reads them lazily, so it costs nothing until someone
opens the licence page.

What it fixed: **bambuddy never registered the OFL licences at all.** Its
`showLicensePage` listed neither Manrope nor JetBrains Mono, and the repository
had no `assets/licenses` — while the OFL requires the licence to travel with the
font it ships. lubelogger had the registration and the two text files; the files
are gone from there now, since the package carries them.

The ref churn this cost, because a package pinned by tag cannot be bumped
alone: `dash_ui` 0.3.0 is released by **v0.9.0**, and `dash_kit` (0.1.1) and
`app_report_ui` (0.1.1) both move their `dash_ui` ref to it — two refs for one
package in a resolution is a version-solving error, not a warning. Both
applications then move `dash_kit` and `app_report_ui` to v0.9.0 as well. Both
resolved through a gitignored `pubspec_overrides.yaml` until the tag existed;
their locks name v0.9.0 now and the overrides are gone.

**JetBrains Mono is the same build in both now.** lubelogger was on 2.211 (115
KB per weight) and bambuddy on 2.304 (274 KB); both carry 2.304 today, taken
from the upstream release and byte-identical to it — 2.304 is the newest there
has been since January 2023, and the ttfautohint in its name table is
JetBrains' own build step, not a local one. It costs lubelogger about 640 KB of
assets. Manrope is 4.504 in both and was never in question.

## 10. ~~Tooling and CI~~ — done, and not versioned

`pages.yml` and `claude.yml` are called now rather than copied: the bodies live
in this repository's [`.github/workflows`](../.github/workflows), and each
application keeps only its trigger — the default branch differs — its
concurrency group, and what it alone grants. A called workflow's
`actions/checkout` and every `github.*` expression in it name the *calling*
repository, which is what lets one copy of the permission gate, the runner setup
and the tool allowlist serve both. `claude.yml` takes the server reference as
two inputs, one extra `--allowedTools` line, and the OAuth token as a secret,
since the two applications hold that token under different names. bambuddy's
retried, time-capped clone of the server reference is the version both now run.

They are pinned at `@master`, not at a tag. Nothing here resolves through pub,
so there is no version solving to break, and a tag would have to be moved for
every workflow fix — the ref churn §9 describes, for no gain.

lubelogger's `ci.yml` caught up with bambuddy's two fixes. The path filter is
decided in a step rather than by `paths-ignore`, so a docs-only pull request
reports the required status instead of waiting for a check that can never
arrive. The formatting gate comes with the one-off `dart format` of the tree —
102 of 142 files, this project predating the tall style — and a
`.git-blame-ignore-revs` naming that commit, the same pair bambuddy landed.

Not moved:

- `tool/check_l10n_sync.py` (495 lines) and `tool/aab_versions.py` (109) are
  byte-identical, and stay duplicated. Both are run from the `justfile`, locally
  and offline, so a reusable workflow cannot deliver them; a submodule, a
  fetch-on-demand recipe or a CI drift check each cost something in every clone
  or every run, against a drift that has not happened yet — the copies have kept
  themselves identical.
- The `justfile`s, for the same reason: `just` imports only a local path, so
  sharing the 27 common recipes means the same submodule.

## Not worth it, or blocked

- **`demo_config`, `report_wiring`, `report_config`, `dash_theme`.** These are
  already the application's half of a shared contract: constants and nothing
  else.
- **`NotificationService`.** Blocked on versions first:
  `flutter_local_notifications` is ^22 in lubelogger and ^18 in bambuddy. The
  models differ too: reminders from WorkManager against a foreground service.
  `package_info_plus` has drifted the same way (^9 against ^8).
- **Server version.** lubelogger compares dotted versions in 30 lines. bambuddy's
  `ServerVersion` reads `-daily` builds and carries a feature table. Different
  meanings.
- **The offline cache, write queue and `RetryInterceptor`** (about 700 lines in
  lubelogger). Generic, but there is no second consumer. It is the same bet as
  `wear_ui`. `RetryInterceptor` is the closest to moving, since bambuddy never
  retries a failed GET, but it reads lubelogger's `OfflineStatus`.
- **Charts.** bambuddy draws with `fl_chart`, lubelogger paints its own.
- **~~Localizations outside the widget tree~~** — ported, not shared.
  lubelogger's `loadAppLocalizations` matched on `languageCode` alone, so a
  phone set to Italian then Polish got English notifications. It now resolves
  through `basicLocaleListResolution` behind a `resolveAppLocale` the tests can
  reach, as in bambuddy, and carries bambuddy's suite adapted to `en`/`pl`.
