# DoYouHost.app-shared

Packages shared between the DoYouHost mobile apps (bambuddy-mobile,
lubelogger-mobile). One package per directory under `packages/`.

Consumed by path while an API is still settling, and by a pinned git tag once it
is not — the same rule the OpenTofu modules follow.

| package | what it is |
|---|---|
| [`app_report_client`](packages/app_report_client) | client half of [app-report-relay](https://github.com/DoYouHost/app-report-relay): ticket transport, on-disk outbox, log redaction |

## Licence

[AGPL-3.0](LICENSE), the same as the applications that consume these packages —
bambuddy-mobile, lubelogger-mobile and the bambuddy server itself.
