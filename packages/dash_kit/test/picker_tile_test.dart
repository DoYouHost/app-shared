import 'package:dash_kit/dash_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double drawing,
  required VoidCallback onTap,
}) => pumpPhone(
  tester,
  Scaffold(
    body: Center(
      child: PickerTile(
        drawing: drawing,
        onTap: onTap,
        child: const ColoredBox(color: Colors.red, key: Key('drawing')),
      ),
    ),
  ),
);

void main() {
  group('PickerTile', () {
    for (final drawing in [36.0, 44.0, 48.0]) {
      testWidgets('is a 48 dp cell around a $drawing dp drawing', (
        tester,
      ) async {
        await _pump(tester, drawing: drawing, onTap: () {});

        expect(
          tester.getSize(find.byType(PickerTile)),
          const Size.square(kMinInteractiveDimension),
        );
        expect(
          tester.getSize(find.byKey(const Key('drawing'))),
          Size.square(drawing),
        );
        expect(
          tester.getCenter(find.byKey(const Key('drawing'))),
          tester.getCenter(find.byType(PickerTile)),
        );
      });
    }

    testWidgets('takes a tap in the cell outside the drawing', (tester) async {
      var taps = 0;
      await _pump(tester, drawing: 36, onTap: () => taps++);

      // 2 dp inside the cell's corner: 4 dp outside the 36 dp drawing.
      final corner = tester.getTopLeft(find.byType(PickerTile));
      await tester.tapAt(corner + const Offset(2, 2));
      expect(taps, 1);

      await tester.tapAt(corner - const Offset(2, 2));
      expect(taps, 1, reason: 'outside the cell is not the tile');
    });

    testWidgets('meets the tap target guideline', (tester) async {
      // The guideline compares with 48 in physical pixels: at the default 3x a
      // 36 dp target would pass.
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await _pump(tester, drawing: 36, onTap: () {});
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    group('gap', () {
      test('takes the cell around the drawing off the old spacing', () {
        expect(PickerTile.gap(44, 8), 4);
        expect(PickerTile.gap(48, 8), 8);
      });

      test('never goes below zero', () {
        expect(PickerTile.gap(36, 8), 0);
        expect(PickerTile.gap(36, 12), 0);
        expect(PickerTile.gap(36, 0), 0);
      });
    });
  });
}
