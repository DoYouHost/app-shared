import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A throwaway directory holding [files] (relative path → contents), removed
/// after the test. The scans take paths, so a test hands them this root.
String tree(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('app_guards');
  addTearDown(() => root.deleteSync(recursive: true));
  files.forEach((path, contents) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  });
  return root.path;
}
