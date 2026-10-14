import 'dart:io';

import 'package:app_guards/src/bundled.dart';

/// `dart run app_guards:play tracks | internal [--dry-run] AAB...` — Google Play
/// publishing, configured by the application's `tool/play.toml`. Runs through
/// uv, which resolves the script's Google API dependencies.
Future<void> main(List<String> args) async => exit(
  await runBundled(
    'uv',
    'play_internal.py',
    args,
    interpreterArgs: ['run', '--quiet'],
  ),
);
