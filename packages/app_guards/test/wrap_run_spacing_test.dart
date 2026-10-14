import 'package:app_guards/app_guards.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  test('a Wrap with spacing and no runSpacing is reported by line', () {
    final root = tree({
      'a.dart': '''
final a = Wrap(spacing: 8, children: [Text('x')]);

final b = Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [Wrap(spacing: 2, children: const [])],
);
''',
    });

    final hits = wrapsWithoutRunSpacing(root: root);

    expect(hits.map((h) => h.split(':').last), ['1', '6']);
  });

  test('a Wrap that sets neither is fine: it has no gap to lose', () {
    final root = tree({'a.dart': 'final a = Wrap(children: const []);'});

    expect(wrapsWithoutRunSpacing(root: root), isEmpty);
  });

  test('a parenthesis inside a string does not end the Wrap', () {
    final root = tree({
      'a.dart': '''
final a = Wrap(
  spacing: 8,
  children: [Text('Filter (active)'), Text('it\\'s (x)')],
  runSpacing: 8,
);
''',
    });

    expect(wrapsWithoutRunSpacing(root: root), isEmpty);
  });

  test('an apostrophe in a comment does not end the Wrap', () {
    final root = tree({
      'a.dart': '''
final a = Wrap(
  // doesn't wrap often (but it can)
  spacing: 8,
  runSpacing: 8,
  children: const [],
);
final b = Wrap(spacing: 4, children: const []); /* it's here */
''',
    });

    final hits = wrapsWithoutRunSpacing(root: root);

    expect(hits.map((h) => h.split(':').last), ['7']);
  });

  test('a triple-quoted string with an apostrophe in it stays a string', () {
    final root = tree({
      'a.dart': """
final a = Wrap(
  spacing: 8,
  children: [Text('''Don't (wrap)''')],
  runSpacing: 8,
);
""",
    });

    expect(wrapsWithoutRunSpacing(root: root), isEmpty);
  });

  test('a string inside an interpolation that reuses the quote stays one', () {
    final root = tree({
      'a.dart': r"""
final a = Wrap(
  spacing: 8,
  children: ['${flag ? ')' : ''}'],
  runSpacing: 8,
);
""",
    });

    expect(wrapsWithoutRunSpacing(root: root), isEmpty);
  });

  test('a file ending inside a string after a backslash does not crash', () {
    final root = tree({'a.dart': r"final a = Wrap(spacing: 8, children: ['x\"});

    expect(() => wrapsWithoutRunSpacing(root: root), returnsNormally);
  });
}
