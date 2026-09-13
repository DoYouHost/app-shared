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

## 5. Small utilities

No design decisions, all already tested, all in bambuddy and all absent or
hand-rolled in lubelogger:

| what | why it is worth sharing |
|---|---|
| `core/models/json_utils.dart` | tolerant JSON coercers; lubelogger hand-parses and has no equivalent |
| `core/format/user_number.dart` | the decimal comma — `double.tryParse` refuses what a Polish keyboard produces |
| `core/format/text_measure.dart` | measuring a label at the ambient `TextScaler`, which is the part that gets forgotten |
| `core/platform/platform_query.dart` | one policy for "this host does not implement the channel" |
| `features/common/format_bytes.dart`, `hex_color.dart` | small, exact, and copied by hand otherwise |
| `core/demo/demo_http_adapter.dart` | already 61% identical |
| `ServerProfile.normalizeBaseUrl` | the http/https/WS bug that a mocked adapter cannot catch |
| the `mapDioException` core of `core/api/api_exceptions.dart` | the same error taxonomy, differently spelled |

Blocker: none, beyond deciding whether they belong in one `app_util` package or
are split by subject. One package is probably right — each of these is too small
to carry its own pubspec.

## A gap in this repository

There was no CI here until `app_diagnostics` landed; the workflow added with it
runs `flutter pub get`, `flutter analyze` and `flutter test` for every directory
under `packages/`. It deliberately does **not** gate `dart format`:
`app_report_client` predates the formatter version the applications are on and
would need an 844-line reformat to go green. That reformat is a decision about
this repository's history — worth making, together with a
`.git-blame-ignore-revs` entry, the way bambuddy did it — and the format gate
should be added in the same commit.
