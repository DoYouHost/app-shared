import 'package:app_guards/app_guards.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('a typed icon size, font size, radius and alpha is reported', () {
    final root = tree({
      'a.dart': '''
final a = Icon(Icons.add, size: 18);
final b = TextStyle(fontSize: 12.5);
final c = BorderRadius.circular(14);
final d = Radius.circular(6);
final e = color.withValues(alpha: 0.35);
final f = IconButton(iconSize: 22, onPressed: null);
final g = IconThemeData(size: 20);
final h = Icon(
  Icons.add,
  size: wide ? 20 : 16,
);
''',
    });

    final hits = rawSizes(root: root);

    expect(hits, hasLength(9));
    expect(hits.first, endsWith('a.dart:1  icon size 18'));
    expect(hits, contains(endsWith('font size 12.5')));
    expect(hits, contains(endsWith('radius 14')));
    expect(hits, contains(endsWith('alpha 0.35')));
  });

  test('the scales, zero, one in an alpha and proportions pass', () {
    final root = tree({
      'a.dart': '''
final a = Icon(Icons.add, size: DashIcon.md);
final b = TextStyle(fontSize: DashFontSize.body);
final c = BorderRadius.circular(DashRadius.lg);
final d = color.withValues(alpha: DashAlpha.wash);
final e = color.withValues(alpha: 1);
final f = color.withValues(alpha: 0.2 * opacity);
final g = Icon(Icons.add, size: box * 0.6);
final h = BorderRadius.circular(height / 2);
final i = BorderRadius.circular(0);
final j = IconButton(iconSize: DashIcon.lg * scale, onPressed: null);
final k = Icon(Icons.add, size: DashIcon.md + 3);
''',
    });

    expect(rawSizes(root: root), hasLength(1));
  });

  test('a number in a comment or a string is not a size', () {
    final root = tree({
      'a.dart': '''
// Icon(Icons.add, size: 18)
final s = 'fontSize: 12';
final t = "BorderRadius.circular(8)";
''',
    });

    expect(rawSizes(root: root), isEmpty);
  });

  test('a skipped path is not read', () {
    final root = tree({'wear/a.dart': 'final a = Icon(x, size: 18);'});

    expect(rawSizes(root: root, skip: {'wear/'}), isEmpty);
    expect(rawSizes(root: root), hasLength(1));
  });

  test('generated localizations are not read', () {
    final root = tree({'l10n/a.dart': 'final a = Icon(x, size: 18);'});

    expect(rawSizes(root: root), isEmpty);
  });
}
