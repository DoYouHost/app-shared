import 'dart:io';

import 'package:app_guards/src/bundled.dart';

/// `dart run app_guards:commit_msg` — The commit-msg hook: one Conventional Commits line, nothing after it.
Future<void> main(List<String> args) async =>
    exit(await runBundled('sh', 'commit-msg', args));
