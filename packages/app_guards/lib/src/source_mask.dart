/// [source] with every comment and every string literal's contents replaced by
/// spaces, newlines kept, so each index still points where it did. A scan that
/// matches brackets on the result cannot be thrown off by a bracket in a label
/// or an apostrophe in a comment.
///
/// Handles `//` and `/* */` comments, single, double and triple quotes, raw
/// strings, escapes and `${…}` interpolations — including a string inside one
/// that reuses the outer quote (`'${a ? ')' : ''}'`), which is blanked with the
/// string around it.
String maskCommentsAndStrings(String source) {
  final out = source.split('');
  void blank(int from, int to) {
    for (var k = from; k < to && k < out.length; k++) {
      if (out[k] != '\n') out[k] = ' ';
    }
  }

  var i = 0;
  while (i < source.length) {
    final comment = _commentEnd(source, i);
    if (comment != null) {
      blank(i, comment);
      i = comment;
      continue;
    }
    final c = source[i];
    if (c == "'" || c == '"') {
      final quote = _quoteAt(source, i);
      final end = _stringEnd(source, i);
      // The quotes stay, so a scan still sees that a string was there.
      blank(i + quote.length, end - quote.length);
      i = end;
      continue;
    }
    i++;
  }
  return out.join();
}

/// Where the comment starting at [i] ends, or null when none starts there.
int? _commentEnd(String source, int i) {
  if (source.startsWith('//', i)) {
    final end = source.indexOf('\n', i);
    return end == -1 ? source.length : end;
  }
  if (source.startsWith('/*', i)) {
    final end = source.indexOf('*/', i + 2);
    return end == -1 ? source.length : end + 2;
  }
  return null;
}

String _quoteAt(String source, int i) =>
    source.startsWith(source[i] * 3, i) ? source[i] * 3 : source[i];

/// The index just past the string literal whose opening quote is at [start];
/// the end of [source] when it never closes.
int _stringEnd(String source, int start) {
  final quote = _quoteAt(source, start);
  final raw = start > 0 && source[start - 1] == 'r';
  final triple = quote.length == 3;
  var k = start + quote.length;
  while (k < source.length) {
    if (source.startsWith(quote, k)) return k + quote.length;
    final c = source[k];
    if (!triple && c == '\n') return k;
    if (!raw && c == r'\') {
      k += 2;
      continue;
    }
    if (!raw && source.startsWith(r'${', k)) {
      k = _interpolationEnd(source, k + 2);
      continue;
    }
    k++;
  }
  return source.length;
}

/// The index just past the `}` closing an interpolation whose code starts at
/// [start], stepping over nested braces, strings and comments.
int _interpolationEnd(String source, int start) {
  var depth = 1;
  var k = start;
  while (k < source.length) {
    final comment = _commentEnd(source, k);
    if (comment != null) {
      k = comment;
      continue;
    }
    final c = source[k];
    if (c == "'" || c == '"') {
      k = _stringEnd(source, k);
      continue;
    }
    if (c == '{') depth++;
    if (c == '}' && --depth == 0) return k + 1;
    k++;
  }
  return source.length;
}
