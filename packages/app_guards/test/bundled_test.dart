import 'dart:io';

import 'package:app_guards/src/bundled.dart';
import 'package:flutter_test/flutter_test.dart';

/// The scripts behind the Dart entry points, run as the entry points run them.
/// Finding the package directory needs `dart run`, so it is not exercised here.
void main() {
  Future<int> commitMsg(String message) {
    final dir = Directory.systemTemp.createTempSync('app_guards');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/MSG')..writeAsStringSync(message);
    return runScript('sh', 'tool/commit-msg', [file.path]);
  }

  test('the hook takes one Conventional Commits line', () async {
    expect(await commitMsg('fix(auth): stop logging out on 403\n'), 0);
  });

  test('the hook refuses a body and a trailer', () async {
    expect(await commitMsg('fix: x\n\nbecause\n'), isNot(0));
    expect(
      await commitMsg('fix: x\n\nCo-Authored-By: someone <a@b.c>\n'),
      isNot(0),
    );
  });

  test('every script an entry point names ships in tool/', () {
    for (final script in [
      'check_l10n_sync.py',
      'aab_versions.py',
      'commit-msg',
    ]) {
      expect(File('tool/$script').existsSync(), isTrue, reason: script);
    }
  });
}
