import 'package:app_guards/app_guards.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('a typed number in padding, a gap or a spacing is reported', () {
    final root = tree({
      'a.dart': '''
const p = EdgeInsets.all(12);
const g = SizedBox(height: 6);
final w = Wrap(spacing: 4, runSpacing: 4);
''',
    });

    final hits = rawSpacing(root: root);

    expect(hits, hasLength(4));
    expect(hits.first, endsWith('a.dart:1  EdgeInsets.all(12)'));
  });

  test('the scale, zero and a size are not spacing', () {
    final root = tree({
      'a.dart': '''
const p = EdgeInsets.all(DashSpace.lg);
const z = EdgeInsets.zero;
const n = EdgeInsets.only(left: 0);
const box = SizedBox(width: double.infinity);
''',
    });

    expect(rawSpacing(root: root), isEmpty);
  });

  test('generated localizations are not read', () {
    final root = tree({'l10n/app_localizations.dart': 'EdgeInsets.all(3)'});

    expect(rawSpacing(root: root), isEmpty);
  });
}
