import 'package:dash_ui/dash_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brands.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double width = 200}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildDashThemeData(Brightness.light, brand: green),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      );

  testWidgets('a label as wide as the room wraps instead of overflowing', (
    tester,
  ) async {
    await pump(
      tester,
      const DashPill(
        label: 'A cause long enough to fill the whole width of its card',
        accent: Color(0xFF1D6F52),
        icon: Icons.warning_amber_rounded,
      ),
      width: 120,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DashPill)).width, lessThanOrEqualTo(120));
  });

  testWidgets('a short label keeps the pill as wide as its content', (
    tester,
  ) async {
    await pump(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: DashPill(label: 'OK', accent: Color(0xFF1D6F52)),
      ),
    );

    expect(tester.getSize(find.byType(DashPill)).width, lessThan(80));
  });
}
