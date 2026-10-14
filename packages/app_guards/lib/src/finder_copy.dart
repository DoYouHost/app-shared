import 'dart:convert';
import 'dart:io';

import 'source_files.dart';

/// Every finder under [root] whose text is a literal that reads as the app's
/// copy, as `path:line  "text"  →  why`. A finder that spells out copy breaks
/// on every wording change; it reads the text from the localizations instead
/// (`find.text(pl.cancel)`).
///
/// What is not copy stays literal: whatever a server or a fixture supplies and
/// the framework's own strings. Those match no message, so only the few that
/// trip [AppCopy.marks] or happen to equal a message go in [allowed], each with
/// its source in the application's test. [skip] leaves out files that quote
/// literals on purpose.
List<String> finderCopy(
  AppCopy copy, {
  Set<String> allowed = const {},
  String root = 'test',
  bool Function(String path)? skip,
}) {
  final offenders = <String>[];
  for (final file in dartFiles(root)) {
    if (skip?.call(file.path) ?? false) continue;
    final source = file.readAsStringSync();
    for (final hit in finderLiterals(source)) {
      final why = copy.explain(hit.text, allowed: allowed);
      if (why != null) {
        offenders.add(
          '${file.path}:${lineOf(source, hit.at)}  ${jsonEncode(hit.text)}'
          '  →  $why',
        );
      }
    }
  }
  return offenders;
}

/// One string literal found as a finder's text argument.
typedef FinderLiteral = ({String text, int at});

final _finder = RegExp(
  r'find\.(text|textContaining|byTooltip|bySemanticsLabel|widgetWithText)\(|'
  r'(matchesSemantics)\(',
);

final _semanticsText = RegExp(r'\b(?:label|tooltip|hint|value):');

/// The text argument of every `find.text(…)`-style call (and the first
/// property of a `matchesSemantics(…)`) in [source]; calls whose
/// text is not one plain literal (a variable, an interpolation, `'a' + b`) are
/// skipped, because there is nothing to compare.
List<FinderLiteral> finderLiterals(String source) {
  final found = <FinderLiteral>[];
  for (final match in _finder.allMatches(source)) {
    var i = match.end;
    if (match.group(2) != null) {
      // Any order, any number of the text properties.
      final call = source.substring(
        i,
        _endOfArgument(source, i, stopAtComma: false),
      );
      for (final property in _semanticsText.allMatches(call)) {
        final literal = _readLiterals(call, property.end);
        if (literal != null) found.add((text: literal.$1, at: match.start));
      }
      continue;
    }
    if (match.group(1) == 'widgetWithText') {
      i = _endOfArgument(source, i);
      if (i >= source.length) continue;
      i++; // the comma
    }
    final literal = _readLiterals(source, i);
    if (literal != null) found.add((text: literal.$1, at: match.start));
  }
  return found;
}

/// Index of the comma that ends the argument starting at [from] (or the
/// closing parenthesis), ignoring commas nested in `()`, `[]`, `{}` and `<>`.
int _endOfArgument(String s, int from, {bool stopAtComma = true}) {
  var depth = 0;
  for (var i = from; i < s.length; i++) {
    switch (s[i]) {
      case '(' || '[' || '{' || '<':
        depth++;
      case ')' || ']' || '}' || '>':
        if (depth == 0) return i;
        depth--;
      case ',' when depth == 0 && stopAtComma:
        return i;
    }
  }
  return s.length;
}

/// Adjacent string literals from [from], joined — and the index after them —
/// when they are the whole argument; null otherwise.
(String, int)? _readLiterals(String s, int from) {
  final out = StringBuffer();
  var i = from;
  var read = 0;
  while (true) {
    while (i < s.length && s[i].trim().isEmpty) {
      i++;
    }
    final one = _readLiteral(s, i);
    if (one == null) break;
    out.write(one.$1);
    i = one.$2;
    read++;
  }
  if (read == 0) return null;
  // `'a' + b` and `'a' ? …` are not a plain literal.
  if (i < s.length && s[i] != ',' && s[i] != ')') return null;
  return (out.toString(), i);
}

const _escapes = {
  'n': '\n',
  't': '\t',
  'r': '\r',
  "'": "'",
  '"': '"',
  r'\': r'\',
  r'$': r'$',
};

(String, int)? _readLiteral(String s, int from) {
  var i = from;
  var raw = false;
  if (i < s.length && s[i] == 'r') {
    raw = true;
    i++;
  }
  if (i >= s.length || (s[i] != "'" && s[i] != '"')) return null;
  final quote = s[i++];
  final out = StringBuffer();
  while (i < s.length) {
    final c = s[i];
    if (c == quote) return (out.toString(), i + 1);
    if (!raw && c == r'$') return null; // interpolated: not a fixed text
    if (!raw && c == r'\') {
      final n = s[i + 1];
      if (n == 'u') {
        final braced = s[i + 2] == '{';
        final end = braced ? s.indexOf('}', i) : i + 6;
        final hex = s.substring(braced ? i + 3 : i + 2, end);
        out.writeCharCode(int.parse(hex, radix: 16));
        i = braced ? end + 1 : end;
        continue;
      }
      if (n == 'x') {
        out.writeCharCode(int.parse(s.substring(i + 2, i + 4), radix: 16));
        i += 4;
        continue;
      }
      out.write(_escapes[n] ?? n);
      i += 2;
      continue;
    }
    out.write(c);
    i++;
  }
  return null;
}

/// One locale's `.arb` values, as the shapes a finder literal could take.
class AppCopy {
  AppCopy(this.prefix, Map<String, List<String>> shapesByKey, {this.marks}) {
    final holes = RegExp('[$_text$_number]');
    shapesByKey.forEach((key, shapes) {
      for (final shape in shapes) {
        if (!shape.contains(holes)) {
          _plain.putIfAbsent(shape, () => []).add(key);
        } else if (shape.replaceAll(holes, '').trim().length >= 5) {
          // Less fixed text than that matches half the alphabet ("$n min").
          final pattern = shape.splitMapJoin(
            holes,
            onMatch: (m) => m[0] == _number ? r'\d+' : '.+?',
            onNonMatch: RegExp.escape,
          );
          _templates[key] = [
            ...?_templates[key],
            RegExp('^$pattern\$', dotAll: true),
          ];
        }
      }
    });
  }

  /// [arb] is the locale the tests render in; [template] holds the
  /// placeholder types, which live in the template file only. [prefix] is the
  /// name the tests read that locale's strings by (`pl`, `en`), used in the
  /// explanation. [marks] is text no server data contains and the app's copy
  /// does — the Polish diacritics, say — caught even where no message matches.
  factory AppCopy.fromArb(
    String arb, {
    required String prefix,
    String template = 'lib/l10n/app_en.arb',
    RegExp? marks,
  }) {
    final values = jsonDecode(File(arb).readAsStringSync()) as Map;
    final meta = jsonDecode(File(template).readAsStringSync());
    Set<String> numeric(String key) {
      final placeholders = (meta['@$key'] as Map?)?['placeholders'] as Map?;
      return {
        for (final e in placeholders?.entries ?? const <MapEntry>[])
          if (const {'int', 'num', 'double'}.contains(e.value['type']))
            e.key as String,
      };
    }

    return AppCopy(prefix, marks: marks, {
      for (final e in values.entries)
        if (!(e.key as String).startsWith('@') && e.value is String)
          e.key as String: _shapes(
            (e.value as String).replaceAll("''", "'"),
            numeric(e.key as String),
          ),
    });
  }

  final String prefix;
  final RegExp? marks;

  /// A placeholder holding free text, and one holding a number.
  static const _text = '\u0000';
  static const _number = '\u0001';
  final _plain = <String, List<String>>{};
  final _templates = <String, List<RegExp>>{};

  /// Why [literal] reads as copy, or null when it does not.
  String? explain(String literal, {required Set<String> allowed}) {
    if (allowed.contains(literal)) return null;
    final keys = _plain[literal];
    if (keys != null) return '$prefix.${keys.first}';
    for (final MapEntry(:key, :value) in _templates.entries) {
      if (value.any((rx) => rx.hasMatch(literal))) return '$prefix.$key(…)';
    }
    // A long fragment of one message ("przestanie działać natychmiast").
    if (literal.trim().length >= 8) {
      for (final MapEntry(:key, :value) in _plain.entries) {
        if (value.isNotEmpty && key.contains(literal)) {
          return 'part of $prefix.${value.first}';
        }
      }
    }
    if (marks?.hasMatch(literal) ?? false) return 'copy text: $prefix.<key>';
    return null;
  }

  /// Every concrete text [message] (ICU) can render as, a `{placeholder}`
  /// standing for [_text] or [_number]. `plural` and `select` branches each
  /// become a shape.
  static List<String> _shapes(String message, Set<String> numeric) {
    var shapes = <String>[''];
    var i = 0;
    while (i < message.length) {
      if (message[i] != '{') {
        final next = message.indexOf('{', i);
        final end = next == -1 ? message.length : next;
        final text = message.substring(i, end);
        shapes = [for (final s in shapes) '$s$text'];
        i = end;
        continue;
      }
      final close = _matching(message, i);
      final inner = message.substring(i + 1, close);
      final comma = inner.indexOf(',');
      final branches = comma == -1
          ? [numeric.contains(inner.trim()) ? _number : _text]
          : _branches(
              inner.substring(inner.indexOf(',', comma + 1) + 1),
              numeric,
            );
      shapes = [
        for (final s in shapes)
          for (final b in branches) '$s$b',
      ];
      i = close + 1;
    }
    return shapes;
  }

  /// Bodies of `selector{body}` pairs, each expanded in turn.
  static List<String> _branches(String list, Set<String> numeric) {
    final bodies = <String>[];
    var i = 0;
    while (true) {
      final open = list.indexOf('{', i);
      if (open == -1) break;
      final close = _matching(list, open);
      bodies.addAll(_shapes(list.substring(open + 1, close), numeric));
      i = close + 1;
    }
    return bodies;
  }

  static int _matching(String s, int open) {
    var depth = 0;
    for (var i = open; i < s.length; i++) {
      if (s[i] == '{') depth++;
      if (s[i] == '}' && --depth == 0) return i;
    }
    return s.length - 1;
  }
}
