import 'dart:io';

import 'package:app_guards/src/bundled.dart';

/// `dart run app_guards:aab_versions` — Prints the versionName/versionCode baked into built Play bundles.
Future<void> main(List<String> args) async =>
    exit(await runBundled('python3', 'aab_versions.py', args));
