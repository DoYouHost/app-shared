import 'dart:io';

import 'package:app_guards/src/bundled.dart';

/// `dart run app_guards:log_coverage [--all-dirs] [--limit N] [--kind NAME]
/// [--json]` — the controls in `lib/` no diagnostic-log identifier reaches,
/// configured by the application's `tool/log_coverage.toml`.
Future<void> main(List<String> args) async =>
    exit(await runBundled('python3', 'log_coverage.py', args));
