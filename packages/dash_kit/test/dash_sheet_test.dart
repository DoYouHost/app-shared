import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const navBar = 48.0;
  final contentKey = UniqueKey();

  /// Screen with a three-button navigation bar along the bottom.
  void withNavBar(WidgetTester tester) {
    tester.view.viewPadding = FakeViewPadding(
      bottom: navBar * tester.view.devicePixelRatio,
    );
    tester.view.padding = FakeViewPadding(
      bottom: navBar * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.reset);
  }

  testWidgets('a sheet ends its content above the navigation bar', (
    tester,
  ) async {
    withNavBar(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => dashSheet<void>(
                context,
                builder: (_) => SizedBox(key: contentKey, height: 120),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final screenBottom = tester.getSize(find.byType(MaterialApp)).height;
    final contentBottom = tester.getRect(find.byKey(contentKey)).bottom;
    expect(screenBottom - contentBottom, greaterThanOrEqualTo(navBar));
  });

  Future<void> openSheet(
    WidgetTester tester, {
    required bool dismissible,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => dashSheet<void>(
                context,
                dismissible: dismissible,
                // Painted, so the drag lands on it rather than passing through
                // an empty box to the barrier.
                builder: (_) => ColoredBox(
                  key: contentKey,
                  color: Colors.white,
                  child: const SizedBox(height: 240),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a sheet closes when dragged down', (tester) async {
    await openSheet(tester, dismissible: true);

    await tester.fling(find.byKey(contentKey), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.byKey(contentKey), findsNothing);
  });

  testWidgets('not dismissible, a drag does not close it either', (
    tester,
  ) async {
    await openSheet(tester, dismissible: false);

    await tester.fling(find.byKey(contentKey), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.byKey(contentKey), findsOneWidget);
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    // Checked on the widget as well: in a test a drag without the handle does
    // not close even a draggable sheet, so the fling alone proves nothing.
    expect(sheet.enableDrag, isFalse);
    expect(
      sheet.showDragHandle,
      isFalse,
      reason: 'no handle inviting a drag that does nothing',
    );
  });
}
