import 'dart:io';

import 'package:app_guards/src/bundled.dart';

/// `dart run app_guards:l10n_sync` — Compares every .arb with the English template — missing, outdated and mismatched keys.
Future<void> main(List<String> args) async =>
    exit(await runBundled('python3', 'check_l10n_sync.py', args));
