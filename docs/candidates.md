# What else could live here

Measured across bambuddy-mobile and lubelogger-mobile in September 2026, while
extracting [`app_diagnostics`](../packages/app_diagnostics). Nothing below is
started; this is the evidence and the blocker for each, so the next round does
not have to re-measure.

The rule that decides all of them is the one `app_report_client` already
follows: a package takes what both applications mean identically, and requires
everything they mean differently as a parameter. Where that parameter list would
be longer than the code, the answer is no.

## 1. lubelogger has not adopted `app_report_client` at all

The largest deletion available, and it needs no design work: the package was
extracted *from* this code.

`lubelogger-mobile/lib/core/diagnostics/` still contains its own
`relay_client.dart` (249), `relay_identity.dart` (33), `relay_pow.dart` (58),
`report_envelope.dart` (126), `report_outbox.dart` (162), `report_sender.dart`
(300) and `log_redactor.dart` (337) — 1265 lines — and its `pubspec.yaml` does
not name `app_report_client`. `relay_client.dart` differs from the package's by
about thirty lines.

Blocker: none technical. It is a change in the other repository, and it should
land together with that app's move onto `app_diagnostics`, since both touch the
same directory.

## 2. `dash_ui` — the design system

The two apps' theme layers are the same system with a different brand accent.
Both define `DashTokens` with the same token names (`cardGradient`,
`cardBorder`, `subCard`, `subCardBorder`, `groupCard`, `textPrimary`,
`textSecondary`, `textTertiary`, `accentOrange`, `accentBlue`, `danger`,
`gaugeTrack`, `hairline`, `dottedRule`, `navBar`, `overlaySurface`,
`overlayBorder`) and the same construction functions: `DashBackground`,
`dashAppBar`, `DashPill`, `dashFieldDecoration`, `dashPrimaryButtonStyle`,
`buildDashThemeData`.

What differs: the accent (`accentGreen`/`accentGreenInk` here,
`accentGold`/`accentGoldInk` there) and a wordmark widget. Plus bambuddy's
`dash_text.dart`, the type scale, which lubelogger has no equivalent of and
would gain.

Blocker: this is a design-system move, not a deduplication, and two earlier
bambuddy rounds refused smaller versions of it for exactly that reason
(`subCardBorder` alone stands in 92 places across 20 files). It should be a
deliberate piece of work on tokens, with a contrast test on both accents, not a
side effect of a refactor.

## 3. `app_report_ui` — the report screen

`bug_report_screen.dart` is 82% identical between the apps,
`bug_report_controller.dart` 82%, `recording_banner.dart` 90%, and
`log_export.dart` / `log_preview.dart` are small and near-identical.

Blocker: localization. Each app owns its `.arb` files, so the package needs
either injected strings or l10n of its own — and the screen renders through the
theme, so it wants `dash_ui` first. Worth doing second, not first.

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
