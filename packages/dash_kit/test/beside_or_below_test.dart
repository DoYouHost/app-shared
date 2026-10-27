import 'package:dash_kit/dash_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _label = SizedBox(key: Key('label'), width: 100, height: 20);

/// A control that fills the width it is given and is 150 wide on its own.
Widget _control({VoidCallback? onTap}) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: onTap,
  child: Row(
    children: [
      Expanded(child: SizedBox(key: const Key('a'), width: 70, height: 40)),
      Expanded(child: SizedBox(key: const Key('b'), width: 75, height: 40)),
    ],
  ),
);

Future<void> _pump(WidgetTester tester, double width, {VoidCallback? onTap}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: BesideOrBelow(
              label: _label,
              control: _control(onTap: onTap),
              gap: 10,
              runGap: 6,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'beside: label left, control at the right edge at its own width',
    (tester) async {
      await _pump(tester, 300);

      expect(
        tester.getTopLeft(find.byKey(const Key('label'))),
        const Offset(0, 10),
      );
      // Two Expanded of the widest child: 2 * 75.
      expect(
        tester.getTopLeft(find.byKey(const Key('a'))),
        const Offset(150, 0),
      );
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dx + 75, 300);
      expect(tester.getSize(find.byType(BesideOrBelow)).height, 40);
    },
  );

  testWidgets('exactly fitting stays beside, one pixel less stacks', (
    tester,
  ) async {
    await _pump(tester, 260);
    expect(tester.getTopLeft(find.byKey(const Key('a'))).dx, 110);

    await _pump(tester, 259);
    expect(tester.getTopLeft(find.byKey(const Key('a'))), const Offset(0, 26));
  });

  testWidgets('stacked: the control spans the full width under the label', (
    tester,
  ) async {
    await _pump(tester, 200);

    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    expect(a.left, 0);
    expect(b.right, 200);
    expect(a.top, 26);
    expect(tester.getSize(find.byType(BesideOrBelow)).height, 66);
  });

  testWidgets('a control that only fills a tight width gets one when stacked', (
    tester,
  ) async {
    Future<void> pump(double width) => tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: BesideOrBelow(
              label: _label,
              // 150 wide on its own, as wide as it is told when told exactly.
              control: const Align(
                key: Key('hugging'),
                widthFactor: 1,
                child: SizedBox(width: 150, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    await pump(300);
    expect(tester.getSize(find.byKey(const Key('hugging'))).width, 150);

    await pump(200);
    expect(tester.getSize(find.byKey(const Key('hugging'))).width, 200);
  });

  testWidgets('the control is tappable beside and stacked', (tester) async {
    var taps = 0;
    await _pump(tester, 300, onTap: () => taps++);
    await tester.tap(find.byKey(const Key('a')), warnIfMissed: false);
    await _pump(tester, 150, onTap: () => taps++);
    await tester.tap(find.byKey(const Key('b')), warnIfMissed: false);

    expect(taps, 2);
  });
}
