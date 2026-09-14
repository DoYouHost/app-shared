import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late BuildContext screen;

  /// Opens the dialog and hands back its pending answer, wrapped so the caller
  /// does not await it by accident before tapping anything.
  Future<({Future<bool> answer})> open(
    WidgetTester tester, {
    String confirmLabel = 'Delete',
    String? cancelLabel,
    bool destructive = true,
    Locale locale = const Locale('en'),
    double textScale = 1,
    String message = "This can't be undone.",
  }) async {
    // A fresh navigator, so a dialog opened earlier in the test is gone.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        locale: locale,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('pl')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            screen = context;
            return const Scaffold();
          },
        ),
      ),
    );
    final answer = confirmDialog(
      screen,
      id: 'confirm.record',
      title: 'Delete this record?',
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    );
    await tester.pumpAndSettle();
    return (answer: answer);
  }

  Rect buttonRect(WidgetTester tester, String label) => tester.getRect(
    find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
  );

  Color? fillOf(WidgetTester tester, String label) => tester
      .widget<FilledButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FilledButton),
        ),
      )
      .style
      ?.backgroundColor
      ?.resolve(const {});

  group('the answer', () {
    testWidgets('confirm answers true', (tester) async {
      final dialog = await open(tester);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(await dialog.answer, isTrue);
    });

    testWidgets('cancel answers false', (tester) async {
      final dialog = await open(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await dialog.answer, isFalse);
    });

    testWidgets('tapping the barrier answers false, not null', (tester) async {
      final dialog = await open(tester);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(await dialog.answer, isFalse);
    });
  });

  group('the layout', () {
    testWidgets('two halves of one width, dismiss on the left', (tester) async {
      await open(tester);

      final cancel = buttonRect(tester, 'Cancel');
      final delete = buttonRect(tester, 'Delete');
      expect(cancel.width, delete.width);
      expect(cancel.height, delete.height);
      expect(cancel.top, delete.top);
      expect(cancel.right, lessThan(delete.left));
    });

    testWidgets('a label that wraps does not leave the pair ragged', (
      tester,
    ) async {
      await open(tester);
      final singleLine = buttonRect(tester, 'Delete').height;

      await open(tester, confirmLabel: 'Delete the vehicle and every record');

      final cancel = buttonRect(tester, 'Cancel');
      final delete = buttonRect(tester, 'Delete the vehicle and every record');
      expect(delete.height, greaterThan(singleLine));
      expect(cancel.height, delete.height);
    });

    testWidgets('a word too long for its half stacks the pair', (tester) async {
      // On a phone in Manrope, "Wiederherstellen" alone rendered as
      // "Wiederher|stellen". The test font is far wider, so the word here has
      // to outgrow a half of the default 800 dp test screen.
      const word = 'Donaudampfschifffahrtsgesellschaft';
      await open(tester, confirmLabel: word);

      final cancel = buttonRect(tester, 'Cancel');
      final confirm = buttonRect(tester, word);
      expect(cancel.left, confirm.left);
      expect(cancel.width, confirm.width);
      expect(cancel.bottom, lessThan(confirm.top), reason: 'dismiss above');
    });

    testWidgets('a larger system font stacks a pair that fitted', (
      tester,
    ) async {
      await open(tester);
      expect(
        buttonRect(tester, 'Cancel').top,
        buttonRect(tester, 'Delete').top,
      );

      // A phone in Manrope stacks "Cancel" near 2x; the wider test font on an
      // 800 dp screen needs more.
      await open(tester, textScale: 4);
      expect(
        buttonRect(tester, 'Cancel').bottom,
        lessThan(buttonRect(tester, 'Delete').top),
      );
    });

    testWidgets('text taller than the screen scrolls instead of clipping', (
      tester,
    ) async {
      await open(tester, textScale: 3, message: 'All values go back. ' * 12);

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(SingleChildScrollView),
        ),
        findsWidgets,
      );
    });

    testWidgets('cancel falls back to the platform word for it', (
      tester,
    ) async {
      await open(tester, locale: const Locale('pl'), confirmLabel: 'Usuń');

      expect(find.text('Anuluj'), findsOneWidget);
    });

    testWidgets('destructive confirms in the danger red', (tester) async {
      await open(tester);

      expect(fillOf(tester, 'Delete'), DashTokens.of(screen).dangerInk);
    });

    testWidgets('otherwise the confirm keeps the theme accent', (tester) async {
      await open(tester, confirmLabel: 'Save anyway', destructive: false);

      expect(fillOf(tester, 'Save anyway'), isNull);
      expect(fillOf(tester, 'Cancel'), isNot(DashTokens.of(screen).dangerInk));
    });
  });

  group('the log', () {
    testWidgets('both buttons are named after the dialog', (tester) async {
      await open(tester);

      expect(byLogId('confirm.record.cancel'), findsOneWidget);
      expect(byLogId('confirm.record.confirm'), findsOneWidget);
    });

    testWidgets('the answer is recorded, the wording is not', (tester) async {
      final recording = Recording();
      await recording.start();
      final dialog = await open(tester);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await dialog.answer;

      final records = await recording.stop();
      final confirm = records.singleWhere((r) => r['evt'] == 'confirm');
      expect(confirm['id'], 'confirm.record');
      expect(confirm['reason'], 'confirmed');
      expect(records.toString(), isNot(contains('Delete this record?')));
    });

    testWidgets('backing out is recorded as cancelled', (tester) async {
      final recording = Recording();
      await recording.start();
      final dialog = await open(tester);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      await dialog.answer;

      final records = await recording.stop();
      expect(
        records.singleWhere((r) => r['evt'] == 'confirm')['reason'],
        'cancelled',
      );
    });
  });
}
