import 'package:app_guards/app_guards.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('AppCopy', () {
    late AppCopy copy;
    setUp(() {
      final dir = tree({
        'app_en.arb': '''{
  "cancel": "Cancel",
  "selected": "Selected: {count}",
  "@selected": {"placeholders": {"count": {"type": "int"}}},
  "skipped": "{count, plural, =1{Skipped 1} other{Skipped {count}}}",
  "@skipped": {"placeholders": {"count": {"type": "int"}}},
  "revoke": "The key stops working immediately and cannot be restored."
}''',
      });
      copy = AppCopy.fromArb(
        '$dir/app_en.arb',
        template: '$dir/app_en.arb',
        prefix: 'en',
        marks: RegExp('[ąę]'),
      );
    });

    test('a whole message, a template and a long fragment are copy', () {
      expect(copy.explain('Cancel', allowed: {}), 'en.cancel');
      expect(copy.explain('Selected: 2', allowed: {}), 'en.selected(…)');
      expect(copy.explain('Skipped 3', allowed: {}), 'en.skipped(…)');
      expect(
        copy.explain('stops working immediately', allowed: {}),
        'part of en.revoke',
      );
    });

    test('a mark catches copy no message matches', () {
      expect(copy.explain('zażółć gęślą', allowed: {}), isNotNull);
    });

    test('server data and an allowed literal are not', () {
      expect(copy.explain('X1C Workshop', allowed: {}), isNull);
      expect(copy.explain('Cancel', allowed: {'Cancel'}), isNull);
    });

    test('finderCopy reports the file and line, and skips what it is told', () {
      final root = tree({
        'a_test.dart': "find.text('x');\nfind.text('Cancel');",
        'quoted_test.dart': "find.text('Cancel');",
      });

      final hits = finderCopy(
        copy,
        root: root,
        skip: (path) => path.endsWith('quoted_test.dart'),
      );

      expect(hits, hasLength(1));
      expect(hits.single, contains('a_test.dart:2'));
      expect(hits.single, endsWith('en.cancel'));
    });
  });

  group('finderLiterals', () {
    List<String> texts(String source) => [
      for (final hit in finderLiterals(source)) hit.text,
    ];

    test('reads the first argument of each text finder', () {
      expect(
        texts(
          "find.text('a'); find.textContaining(\"b\"); find.byTooltip('c'); "
          "find.bySemanticsLabel('d');",
        ),
        ['a', 'b', 'c', 'd'],
      );
    });

    test('reads every text property of matchesSemantics, in any order', () {
      expect(texts("matchesSemantics(label: 'a', isButton: true)"), ['a']);
      expect(texts("matchesSemantics(isButton: true, label: 'a')"), ['a']);
      expect(
        texts("matchesSemantics(tooltip: 'a', hint: 'b', isEnabled: true)"),
        ['a', 'b'],
      );
      expect(texts('matchesSemantics(isButton: true)'), isEmpty);
    });

    test('reads the second argument of widgetWithText', () {
      expect(texts("find.widgetWithText(FilledButton, 'Zapisz')"), ['Zapisz']);
      // A comma inside generics is not the argument separator.
      final generic = texts("find.widgetWithText(List<int>, 'x')");
      expect(generic, ['x']);
    });

    test('decodes escapes and joins adjacent literals', () {
      expect(texts(r"find.text('a b\'c\n')"), ['a b\'c\n']);
      expect(texts("find.text('one '\n    'two')"), ['one two']);
      expect(texts(r"find.text('w\xa0tle')"), ['w\u00A0tle']);
      expect(texts(r"find.text(r'\n')"), [r'\n']);
    });

    test('skips what it cannot know', () {
      expect(texts('find.text(l10n.cancel)'), isEmpty);
      expect(texts(r"find.text('a $b')"), isEmpty);
      expect(texts(r"find.text('a ${b}')"), isEmpty);
      expect(texts("find.text('a' + b)"), isEmpty);
      expect(texts('find.text('), isEmpty);
    });
  });
}
