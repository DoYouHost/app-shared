import 'dart:io';
import 'dart:typed_data';

import 'package:app_guards/src/bundled.dart';
import 'package:flutter_test/flutter_test.dart';

/// `tool/store_images.py`: the store screenshots a `play.toml` lists, held to
/// Play's limits before `play screenshots` opens an edit.
void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('store_images');
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  /// A file holding only a PNG's signature and IHDR, which is all the check reads.
  String png(String name, int width, int height) {
    final bytes = ByteData(24)
      ..setUint32(16, width)
      ..setUint32(20, height);
    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (var i = 0; i < signature.length; i++) {
      bytes.setUint8(i, signature[i]);
    }
    final file = File('${dir.path}/$name')
      ..writeAsBytesSync(bytes.buffer.asUint8List());
    return file.path;
  }

  /// Runs the check on a `[screenshots]` table of [lists] (key → paths).
  Future<int> check(Map<String, List<String>> lists) {
    final table = [
      '[screenshots]',
      for (final MapEntry(:key, :value) in lists.entries)
        '$key = [${value.map((p) => '"$p"').join(', ')}]',
    ].join('\n');
    final config = File('${dir.path}/play.toml')..writeAsStringSync(table);
    return runScript('python3', 'tool/store_images.py', [config.path]);
  }

  test('a set within every limit passes', () async {
    expect(
      await check({
        'phone': [png('p.png', 1080, 1920), png('l.png', 1920, 1080)],
        'tablet10': [png('t.png', 1600, 2560)],
        'wear': [png('w.png', 384, 384)],
      }),
      0,
    );
  });

  test('a long side over twice the short one is refused', () async {
    expect(
      await check({
        'phone': [png('p.png', 1080, 2400)],
      }),
      1,
    );
  });

  test('nine for one device type is one too many; eight is not', () async {
    final shots = [for (var i = 0; i < 9; i++) png('$i.png', 1080, 1920)];
    expect(await check({'phone': shots}), 1);
    expect(await check({'phone': shots.take(8).toList()}), 0);
  });

  test('a watch screenshot is square and at least 384 px', () async {
    expect(
      await check({
        'wear': [png('w.png', 384, 400)],
      }),
      1,
    );
    expect(
      await check({
        'wear': [png('w.png', 320, 320)],
      }),
      1,
    );
  });

  test('outside 320 to 3840 px is refused', () async {
    expect(
      await check({
        'phone': [png('p.png', 300, 500)],
      }),
      1,
    );
    expect(
      await check({
        'tablet10': [png('t.png', 2400, 4000)],
      }),
      1,
    );
  });

  test(
    'a missing file, a non-PNG and an unknown device type are refused',
    () async {
      expect(
        await check({
          'phone': ['${dir.path}/nope.png'],
        }),
        1,
      );
      final text = File('${dir.path}/x.png')..writeAsStringSync('not an image');
      expect(
        await check({
          'phone': [text.path],
        }),
        1,
      );
      expect(
        await check({
          'watch': [png('w.png', 384, 384)],
        }),
        1,
      );
    },
  );
}
