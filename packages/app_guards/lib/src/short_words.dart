import 'dart:convert';
import 'dart:io';

/// A letter on its own: not after a letter, a digit or a placeholder (the "h"
/// of "1h" and "{hours}h" is a unit, not a word), and not after an apostrophe,
/// where it is the tail of "don't" — followed by a space a line could break at.
final _shortWord = RegExp(r"(?<![\p{L}\p{N}_'’}])(\p{L}) ", unicode: true);

/// The one-letter units the copy uses ("24 h", "{grams} g", "5 s", "7 j",
/// "{watts} W"). After a number or a placeholder only these are units; any
/// other letter there is a word ("{name} a échoué", "{count} w kolejce").
const _units = 'hsdgjW';
final _unit = RegExp(
  "([0-9}]) (?=[$_units](?![\\p{L}\\p{N}_'’]))",
  unicode: true,
);
final _unitBefore = RegExp(r'[0-9}][  ]$');

const _nbsp = ' ';

/// [text] with every one-letter word glued to the word after it by a no-break
/// space, so no line ends on it — in any language: the Polish "i" and "w", the
/// English "a", the French "à". A one-letter unit stays apart from what follows
/// it and is glued to its number instead.
String glueShortWords(String text) => text
    .replaceAllMapped(_shortWord, (m) {
      final letter = m.group(1)!;
      final before = m.input.substring(m.start < 2 ? 0 : m.start - 2, m.start);
      if (_units.contains(letter) && _unitBefore.hasMatch(before)) {
        return m.group(0)!;
      }
      return '$letter$_nbsp';
    })
    .replaceAllMapped(_unit, (m) => '${m.group(1)}$_nbsp');

/// The `.arb` files under [l10nDir], in a stable order.
List<File> arbFiles(String l10nDir) =>
    Directory(l10nDir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Every translated string under [l10nDir] that [glueShortWords] would still
/// change: a line could end on its one-letter word.
List<String> unGluedShortWords({String l10nDir = 'lib/l10n'}) {
  final offenders = <String>[];
  for (final file in arbFiles(l10nDir)) {
    final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    arb.forEach((key, value) {
      if (key.startsWith('@') || value is! String) return;
      if (glueShortWords(value) != value) {
        offenders.add('${file.path} $key: "$value"');
      }
    });
  }
  return offenders;
}

/// A JSON string literal starting at the opening quote.
final _jsonString = RegExp(r'"(?:[^"\\]|\\.)*"');

/// Rewrites every `.arb` file under [l10nDir] through [glueShortWords].
/// Only the top-level strings that change are touched, in place: an `.arb`
/// laid out by hand — blank lines between groups, placeholders on one line —
/// keeps its layout, and an `@key` block is metadata, never copy. Returns how
/// many strings changed per file.
Map<String, int> glueArbFiles({String l10nDir = 'lib/l10n'}) {
  final changed = <String, int>{};
  for (final file in arbFiles(l10nDir)) {
    final text = file.readAsStringSync();
    final out = StringBuffer();
    var count = 0;
    var depth = 0;
    var i = 0;
    String? key;
    while (i < text.length) {
      final c = text[i];
      if (c == '"') {
        final literal = _jsonString.matchAsPrefix(text, i)!.group(0)!;
        var written = literal;
        final pairKey = key;
        if (depth == 1 && pairKey == null) {
          key = jsonDecode(literal) as String;
        } else if (depth == 1 && pairKey != null) {
          // The value of the top-level pair whose key was just read.
          final value = jsonDecode(literal) as String;
          final glued = glueShortWords(value);
          if (!pairKey.startsWith('@') && glued != value) {
            written = jsonEncode(glued);
            count++;
          }
          key = null;
        }
        out.write(written);
        i += literal.length;
        continue;
      }
      if (c == '{' || c == '[') depth++;
      if (c == '}' || c == ']') depth--;
      // The pair ends here; its value was an object (an `@key` block).
      if (c == ',' && depth == 1) key = null;
      out.write(c);
      i++;
    }
    file.writeAsStringSync(out.toString());
    changed[file.path] = count;
  }
  return changed;
}
