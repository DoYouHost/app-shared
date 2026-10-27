import 'package:dash_kit/dash_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _tile(String text, {Key? key}) =>
    Container(key: key, color: const Color(0xFFCCCCCC), child: Text(text));

Future<void> _pump(
  WidgetTester tester,
  List<Widget> children, {
  double width = 400,
  double minTileWidth = 150,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ContentGrid(
              minTileWidth: minTileWidth,
              spacing: 8,
              runSpacing: 8,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('columnsFor', () {
    for (final (width, min, expected) in [
      (400.0, 150.0, 2), // 2 * 150 + 8 fits
      (307.0, 150.0, 1), // one pixel short of two columns
      (308.0, 150.0, 2), // exactly two columns and the gap
      (100.0, 150.0, 1), // narrower than one tile: still one column
      (0.0, 150.0, 1), // nothing to lay out in: no division by zero
      (1000.0, 150.0, 6),
    ]) {
      test('$width dp, tiles of at least $min dp → $expected', () {
        expect(
          ContentGrid.columnsFor(width, minTileWidth: min, spacing: 8),
          expected,
        );
      });
    }
  });

  testWidgets('a row is as tall as its tallest tile and the others stretch', (
    tester,
  ) async {
    await _pump(tester, [
      _tile('one', key: const Key('a')),
      _tile('two\nlines\nhere', key: const Key('b')),
      _tile('three', key: const Key('c')),
    ]);
    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    final c = tester.getRect(find.byKey(const Key('c')));
    expect(a.height, b.height);
    expect(a.height, greaterThan(40)); // the three-line tile sets it
    expect(c.top, a.bottom + 8); // runSpacing
    expect(c.height, lessThan(a.height)); // its own row, its own height
  });

  testWidgets('a last tile alone keeps one column width', (tester) async {
    await _pump(tester, [
      _tile('x', key: const Key('a')),
      _tile('y'),
      _tile('z', key: const Key('c')),
    ]);
    final a = tester.getRect(find.byKey(const Key('a')));
    final c = tester.getRect(find.byKey(const Key('c')));
    expect(c.width, a.width);
    expect(c.left, a.left);
  });

  testWidgets('a larger minimum width takes a column away', (tester) async {
    await _pump(tester, [_tile('x'), _tile('y')]);
    expect(tester.getRect(find.text('y')).left, greaterThan(100));
    await _pump(tester, [_tile('x'), _tile('y')], minTileWidth: 250);
    expect(tester.getRect(find.text('y')).left, lessThan(50));
  });

  testWidgets('a tile that grows with the text scale grows its row', (
    tester,
  ) async {
    Future<double> rowHeight(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            // copyWith on the ambient data: a bare MediaQueryData drops the window.
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 400,
                    child: ContentGrid(
                      minTileWidth: 150,
                      children: [_tile('Ab', key: const Key('a'))],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byKey(const Key('a'))).height;
    }

    final normal = await rowHeight(1);
    final large = await rowHeight(2);
    expect(large, closeTo(normal * 2, 2));
  });

  testWidgets('no children: nothing is built and nothing throws', (
    tester,
  ) async {
    await _pump(tester, const []);
    expect(tester.takeException(), isNull);
    expect(find.byType(IntrinsicHeight), findsNothing);
  });
}
