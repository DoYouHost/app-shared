import 'dart:io';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every control identifier in this package, read off the source.
///
/// `confirmDestructive` builds its buttons' ids from the one its caller passes,
/// so what counts there is the id at each call site, not the `$id` template.
List<String> _declaredTags() {
  final tagged = RegExp(r"""logTag\(\s*'([^']*)'|\.tagged\(\s*'([^']*)'""");
  final dialog = RegExp(
    r"confirmDestructive\([^;]*?id:\s*'([^']*)'",
    dotAll: true,
  );
  final comment = RegExp(r'^\s*//.*$', multiLine: true);
  final found = <String>[];
  for (final entity in Directory('lib/src').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync().replaceAll(comment, '');
    for (final match in tagged.allMatches(source)) {
      final id = match.group(1) ?? match.group(2)!;
      if (!id.startsWith(r'$id.')) found.add(id);
    }
    for (final match in dialog.allMatches(source)) {
      found.addAll(['${match.group(1)}.cancel', '${match.group(1)}.confirm']);
    }
  }
  return found;
}

void main() {
  test('every control here is named so the probe can skip it', () {
    // The recorder must not record the user operating the recorder, and this
    // prefix is how the probe tells.
    final tags = _declaredTags();
    // A guard that finds nothing is a guard that is not running.
    expect(tags.length, greaterThan(10));
    expect(tags.contains('bug_report.discard.confirm'), isTrue);
    expect(
      tags.where((id) => !id.startsWith(InteractionProbe.ownUiPrefix)),
      isEmpty,
    );
  });

  test('every identifier is a dotted, unlocalized name', () {
    final shape = RegExp(r'^\w+(\.\w+)*$');
    expect(_declaredTags().where((id) => !shape.hasMatch(id)), isEmpty);
  });
}
