import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('dashAppBar', () {
    testWidgets('is named chrome.appbar, back button included', (tester) async {
      await pumpPhone(
        tester,
        Builder(
          builder: (context) =>
              Scaffold(appBar: dashAppBar(context, title: 'Garage')),
        ),
      );

      expect(
        find.descendant(
          of: byLogId('chrome.appbar'),
          matching: find.byType(AppBar),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps the height a bottom adds', (tester) async {
      late PreferredSizeWidget bar;
      await pumpPhone(
        tester,
        Builder(
          builder: (context) {
            bar = dashAppBar(
              context,
              title: 'Garage',
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: SizedBox(),
              ),
            );
            return Scaffold(appBar: bar);
          },
        ),
      );

      expect(bar.preferredSize.height, kToolbarHeight + 48);
    });
  });

  testWidgets('dashSaveAction goes dead while busy', (tester) async {
    Future<void> pumpAction({required bool busy}) => pumpPhone(
      tester,
      Scaffold(
        body: dashSaveAction(
          id: 'form.save',
          label: 'Save',
          busy: busy,
          onPressed: () {},
        ),
      ),
    );

    await pumpAction(busy: false);
    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isTrue);
    expect(byLogId('form.save'), findsOneWidget);

    await pumpAction(busy: true);
    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isFalse);
  });

  group('MaxContentWidth', () {
    testWidgets('caps and centres the child', (tester) async {
      await pumpPhone(
        tester,
        const MaxContentWidth(maxWidth: 300, child: SizedBox.expand()),
      );

      final box = tester.getRect(find.byType(SizedBox));
      expect(box.width, 300);
      expect(box.center.dx, tester.getCenter(find.byType(MaxContentWidth)).dx);
    });

    testWidgets('without a cap, the child is left alone', (tester) async {
      await pumpPhone(
        tester,
        const MaxContentWidth(maxWidth: null, child: SizedBox.expand()),
      );

      expect(
        tester.getSize(find.byType(SizedBox)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });
  });

  testWidgets('SectionHeading is a heading to a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPhone(
      tester,
      const Scaffold(body: SectionHeading('Filaments', style: null)),
    );

    expect(
      tester.getSemantics(find.text('Filaments')),
      matchesSemantics(label: 'Filaments', isHeader: true),
    );
    semantics.dispose();
  });
}
