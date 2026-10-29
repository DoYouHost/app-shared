import 'source_files.dart';
import 'source_mask.dart';

/// Where a size is typed: the part after the label, up to the next comma or the
/// end of its call.
final _labels = <(String, RegExp)>[
  ('icon size', RegExp(r'(?<![\w.])iconSize:\s*')),
  ('font size', RegExp(r'(?<![\w.])fontSize:\s*')),
  ('alpha', RegExp(r'(?<![\w.])alpha:\s*')),
  ('radius', RegExp(r'\b(?:BorderRadius|Radius)\.circular\(\s*')),
];
final _iconCall = RegExp(r'(?<![\w.])(?:Icon|IconThemeData)\(');
final _sizeLabel = RegExp(r'(?<![\w.])size:\s*');
final _number = RegExp(r'(?<![\w.$])(\d+(?:\.\d+)?)(?![\w.])');

/// Every icon size, font size, corner radius and alpha under [root] typed as a
/// number rather than taken from its scale: `DashIcon`, `DashFontSize` (or a
/// `DashTokens` text style), `DashRadius` and `DashAlpha`, all in `dash_ui`.
///
/// What passes: a token; zero and one in an alpha (transparent, opaque); zero in
/// a radius; a number that is only a factor or a divisor of something measured
/// (`size * 0.6`, `height / 2`), because that is a proportion, not a size.
/// Generated localizations are skipped, and so is any path that contains one of
/// [skip]: a watch face has its own type scale, which is not this one.
///
/// A size that is none of these (a strip's height, a panel's width) belongs in a
/// named constant that says what it is for; the scan does not read constants,
/// which is the point.
List<String> rawSizes({String root = 'lib', Set<String> skip = const {}}) {
  final offenders = <String>[];
  for (final file in dartFiles(root)) {
    if (file.path.contains('/l10n/')) continue;
    if (skip.any(file.path.contains)) continue;
    final source = file.readAsStringSync();
    final code = maskCommentsAndStrings(source);
    final found = <(int, String)>[];
    void check(String what, int exprStart, int exprEnd) {
      final expr = code.substring(exprStart, exprEnd);
      for (final n in _number.allMatches(expr)) {
        final value = double.parse(n.group(1)!);
        if (value == 0) continue;
        if (what == 'alpha' && value == 1) continue;
        final before = expr.substring(0, n.start).trimRight();
        final after = expr.substring(n.end).trimLeft();
        final factor =
            before.endsWith('*') ||
            before.endsWith('/') ||
            after.startsWith('*') ||
            after.startsWith('/');
        if (factor) continue;
        found.add((
          exprStart + n.start,
          '${file.path}:${lineOf(source, exprStart + n.start)}  '
              '$what ${n.group(1)}',
        ));
      }
    }

    for (final (what, pattern) in _labels) {
      for (final m in pattern.allMatches(code)) {
        check(what, m.end, _expressionEnd(code, m.end));
      }
    }
    for (final call in _iconCall.allMatches(code)) {
      final argsEnd = _expressionEnd(code, call.end, closeAtBracket: true);
      final args = code.substring(call.end, argsEnd);
      for (final m in _sizeLabel.allMatches(args)) {
        final start = call.end + m.end;
        check('icon size', start, _expressionEnd(code, start));
      }
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    offenders.addAll(found.map((f) => f.$2));
  }
  return offenders;
}

/// The end of the expression starting at [start]: the next comma, or the bracket
/// that closes what it sits in, at its own depth.
int _expressionEnd(String code, int start, {bool closeAtBracket = false}) {
  var depth = 0;
  for (var i = start; i < code.length; i++) {
    switch (code[i]) {
      case '(' || '[' || '{':
        depth++;
      case ')' || ']' || '}':
        if (depth == 0) return i;
        depth--;
      case ',' when depth == 0 && !closeAtBracket:
        return i;
    }
  }
  return code.length;
}
