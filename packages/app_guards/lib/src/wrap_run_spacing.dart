import 'source_files.dart';

final _wrap = RegExp(r'\bWrap\(');

/// Every `Wrap` under [root] that sets `spacing` and not `runSpacing`.
///
/// `spacing` is the gap within a run; the gap between runs is `runSpacing`,
/// which defaults to zero. Such a row looks right until it wraps — at a narrow
/// width or a larger system text size — and then its children touch.
List<String> wrapsWithoutRunSpacing({String root = 'lib'}) {
  final offenders = <String>[];
  for (final file in dartFiles(root)) {
    final source = file.readAsStringSync();
    for (final match in _wrap.allMatches(source)) {
      var depth = 0;
      var i = match.end - 1;
      for (; i < source.length; i++) {
        depth += switch (source[i]) {
          '(' => 1,
          ')' => -1,
          _ => 0,
        };
        if (depth == 0) break;
      }
      final arguments = source.substring(match.end, i);
      if (arguments.contains('spacing:') &&
          !arguments.contains('runSpacing:')) {
        offenders.add('${file.path}:${lineOf(source, match.start)}');
      }
    }
  }
  return offenders;
}
