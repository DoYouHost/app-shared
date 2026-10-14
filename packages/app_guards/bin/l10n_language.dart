import 'dart:io';

import 'package:app_guards/src/bundled.dart';

/// `dart run app_guards:l10n_language [--all] [--base REF] [--lang pl,en]` —
/// LanguageTool on the strings a branch changed, configured by the
/// application's `tool/l10n_language.toml`. `LANGUAGETOOL_URL` picks the server.
Future<void> main(List<String> args) async =>
    exit(await runBundled('python3', 'check_l10n_language.py', args));
