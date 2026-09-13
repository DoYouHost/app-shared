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
| [`dash_ui`](packages/dash_ui) | the design system — tokens resolved per brightness and brand, the type scale, the screen chrome, the Material theme, and the contrast audit each app runs on its brand |
| [`app_util`](packages/app_util) | small things both apps need the same way — tolerant JSON coercion, user-typed numbers, text measurement, platform-channel queries, byte sizes and hex colours, the demo-mode HTTP adapter, the server address, and the classification of a failed request |

[`docs/candidates.md`](docs/candidates.md) lists what else was measured as
shareable, with the blocker on each.

## Licence

[AGPL-3.0](LICENSE), the same as the applications that consume these packages —
bambuddy-mobile, lubelogger-mobile and the bambuddy server itself.
