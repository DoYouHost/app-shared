import 'dart:io';

import 'package:app_guards/app_guards.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

const nbsp = ' ';

void main() {
  group('glueShortWords', () {
    test('a one-letter word is glued to the next, in any language', () {
      expect(glueShortWords('Kot i pies'), 'Kot i${nbsp}pies');
      expect(glueShortWords('w kolejce'), 'w${nbsp}kolejce');
      expect(glueShortWords('a cat'), 'a${nbsp}cat');
      expect(glueShortWords('prête à partir'), 'prête à${nbsp}partir');
    });

    test('a unit is glued to its number, not to what follows', () {
      expect(glueShortWords('za 24 h koniec'), 'za 24${nbsp}h koniec');
      expect(glueShortWords('{grams} g left'), '{grams}${nbsp}g left');
    });

    test(
      'a letter after a number or placeholder that is no unit is a word',
      () {
        expect(glueShortWords('{count} w kolejce'), '{count} w${nbsp}kolejce');
      },
    );

    test('the tail of an elision or a unit stuck to its number is left', () {
      expect(glueShortWords("don't s top"), "don't s${nbsp}top");
      expect(glueShortWords('1h left'), '1h left');
    });

    test('already glued text does not change', () {
      const glued = 'Kot i pies, 24 h';
      expect(glueShortWords(glued), glued);
    });
  });

  test('unGluedShortWords names each string a line could still end on', () {
    final dir = tree({
      'app_pl.arb': '{"a": "Kot i pies", "@a": {}, "b": "Kot i pies"}',
      'app_en.arb': '{"c": "plain"}',
    });

    final hits = unGluedShortWords(l10nDir: dir);

    expect(hits, hasLength(1));
    expect(hits.single, contains('app_pl.arb a:'));
  });

  test('glueArbFiles rewrites the files and the scan is then clean', () {
    final dir = tree({
      'app_pl.arb': '{\n  "a": "Kot i pies",\n  "@a": {}\n}\n',
    });

    expect(glueArbFiles(l10nDir: dir).values, [1]);
    expect(unGluedShortWords(l10nDir: dir), isEmpty);
  });

  test('glueArbFiles touches only the strings it glues', () {
    const layout =
        '{\n  "a": "Kot i pies",\n\n  "b": "plain",\n'
        '  "@b": { "placeholders": { "x": { "type": "String" } } }\n}\n';
    final dir = tree({'app_pl.arb': layout});

    glueArbFiles(l10nDir: dir);

    expect(
      File('$dir/app_pl.arb').readAsStringSync(),
      layout.replaceFirst('i pies', 'i\u00A0pies'),
      reason:
          'a hand-laid file keeps its blank lines and one-line objects, '
          'and the metadata is not copy',
    );
  });
}
