# DoYouHost.app-shared

Packages shared between the DoYouHost mobile apps (bambuddy-mobile,
lubelogger-mobile). One package per directory under `packages/`.

Consumed by path while an API is still settling, and by a pinned git tag once it
is not — the same rule the OpenTofu modules follow.

| package | what it is |
|---|---|
| [`app_report_client`](packages/app_report_client) | client half of [app-report-relay](https://github.com/DoYouHost/app-report-relay): ticket transport, on-disk outbox, log redaction |
| [`app_diagnostics`](packages/app_diagnostics) | the other half — the recording session, the log record and its file mirror, the cross-isolate merge, the review summary, and the probes over taps, routes, requests, errors and lifecycle |
| [`app_report_ui`](packages/app_report_ui) | the report screens — the guided flow, the recording bar that follows the user around the app, and the review that decides where the log goes |
| [`dash_ui`](packages/dash_ui) | the design system — tokens resolved per brightness and brand (a brand may carry its own grounds, `DashSurfaces`, or be generated from a Material scheme pair with `DashBrand.fromSchemes`), the type scale, the spacing scales (`DashSpace`, and Wear Material 3's `WearSpace` for a watch), the screen chrome, the Material theme, and the contrast audit each app runs on its brand |
| [`dash_kit`](packages/dash_kit) | the Dash widgets that name themselves in the diagnostic log — the confirmation dialog, the load-error and empty views, the bottom sheet, the snack bar, the width cap, the spinners, the button pair, the logged app bar, the form fields — the select, the filter select and the picker field — the date pickers, the segmented toggle, the settings rows, the search field and bar, the stepper, the progress bar, the inline note, the sheet surfaces and the refresh-on-return wrapper |
| [`app_guards`](packages/app_guards) | source scans that hold an application to the Dash standards, for its tests to assert on — spacing from `DashSpace` (or, on a watch, `WearSpace`), a `Wrap` that sets `runSpacing`, no one-letter word at a line end, no finder spelling out the copy — and the tools both applications run from their `justfile`: the one-letter-word glue, the LanguageTool check, the log-coverage scan, the translation-sync report, the Play bundle versions, Google Play publishing and the commit-message hook — each configured by a file in the application |
| [`app_test_kit`](packages/app_test_kit) | the test harness both applications need the same way — a request log to assert on, an exact-body mock server, a scripted adapter, a clock and a timer the test drives, the diagnostic-id finders, a phone-shaped window and fixtures |
| [`app_util`](packages/app_util) | small things both apps need the same way — tolerant JSON coercion, user-typed numbers, text measurement, platform-channel queries, byte sizes and hex colours, the demo-mode HTTP adapter, the server address, the web-link filter, the reconnect backoff, server reachability, currency symbols, name ordering and a stable digest, and the classification of a failed request |

Besides the packages, [`.github/workflows`](.github/workflows) holds the two
workflows both applications call rather than copy: the GitHub Pages deploy and
the `@claude` job with its permission gate. Each application keeps its own
trigger and passes in what differs. They are called at `@master` rather than at
a tag — nothing about them resolves through pub, so a fix here should reach both
applications without waiting for a release.

[`docs/candidates.md`](docs/candidates.md) lists what else was measured as
shareable, with the blocker on each.

## Licence

[AGPL-3.0](LICENSE), the same as the applications that consume these packages —
bambuddy-mobile, lubelogger-mobile and the bambuddy server itself.
