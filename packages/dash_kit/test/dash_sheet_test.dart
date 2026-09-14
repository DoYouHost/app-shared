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
}
