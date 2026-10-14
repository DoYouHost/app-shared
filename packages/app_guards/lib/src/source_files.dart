import 'dart:io';

/// Every `.dart` file under [root], in a stable order.
List<File> dartFiles(String root) =>
    Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// 1-based line of [offset] in [source].
int lineOf(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;
