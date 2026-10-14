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
}
