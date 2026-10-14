import 'source_files.dart';

final _literal = RegExp(
  r'EdgeInsets(?:Directional)?\.\w+\(([^()]*)\)'
  r'|SizedBox\((?:width|height): ([\d.]+)\)'
  r'|\b(?:runSpacing|spacing|crossAxisSpacing|mainAxisSpacing'
  r'|indent|endIndent): ([\d.]+)\b',
);
final _number = RegExp(r'(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])');

/// Every padding, margin and gap under [root] typed as a number rather than
/// taken from `DashSpace`. Zero is allowed: it is the absence of spacing, not a
/// value on the scale. Generated localizations are skipped.
///
/// A value that is a size rather than spacing (room for a gauge, centring a
/// knob) belongs in a named constant next to the widget it measures; the scan
/// does not see through constants, which is the point.
List<String> rawSpacing({String root = 'lib'}) {
  final offenders = <String>[];
  for (final file in dartFiles(root)) {
    if (file.path.contains('/l10n/')) continue;
    final source = file.readAsStringSync();
    for (final m in _literal.allMatches(source)) {
      final args = m.group(1) ?? m.group(2) ?? m.group(3)!;
      final nonZero = _number
          .allMatches(args)
          .map((n) => double.parse(n.group(1)!))
          .any((v) => v != 0);
      if (nonZero) {
        offenders.add('${file.path}:${lineOf(source, m.start)}  ${m.group(0)}');
      }
    }
  }
  return offenders;
}
