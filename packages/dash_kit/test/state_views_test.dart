import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  const message = 'Could not load your vehicles.';

  AsyncErrorView errorView({bool scrollable = false, String? surface}) =>
      AsyncErrorView(
        message: message,
        onRetry: () {},
        retryLabel: 'Retry',
        scrollable: scrollable,
        surface: surface,
      );

  Future<void> pumpBody(WidgetTester tester, Widget body) =>
      pumpPhone(tester, logSurface('garage', Scaffold(body: body)));

  group('AsyncErrorView', () {
    testWidgets('sits in the middle of the body, scrollable or not', (
      tester,
    ) async {
      await pumpBody(tester, errorView());
      final bodyCentre = tester.getCenter(find.byType(Scaffold)).dy;
      final plain = tester.getCenter(find.text(message)).dy;

      await pumpBody(tester, errorView(scrollable: true));
      final scrollable = tester.getCenter(find.text(message)).dy;

      expect(scrollable, plain);
      // The column is centred, not the message line inside it.
      expect((plain - bodyCentre).abs(), lessThan(40));
    });

    testWidgets('scrollable, a pull reaches the refresh indicator', (
      tester,
    ) async {
      var refreshed = false;
      await pumpBody(
        tester,
        RefreshIndicator(
          onRefresh: () async => refreshed = true,
          child: errorView(scrollable: true),
        ),
      );

      await tester.fling(find.text(message), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('names the retry for the log', (tester) async {
      await pumpBody(tester, errorView());

      expect(byLogId('error.retry'), findsOneWidget);
    });

    testWidgets('a null icon leaves the glyph out', (tester) async {
      await pumpBody(
        tester,
        AsyncErrorView(
          message: message,
          onRetry: () {},
          retryLabel: 'Retry',
          icon: null,
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('records the screen it gave up on, without the message', (
      tester,
    ) async {
      final recording = Recording();
      await recording.start();
      await pumpBody(tester, errorView());

      final records = await recording.stop();
      final record = records.singleWhere((r) => r['evt'] == 'error_view');
      expect(record['surface'], 'garage');
      expect(record['lvl'], 'warn');
      expect(records.toString(), isNot(contains(message)));
    });

    testWidgets('an explicit surface wins over the enclosing one', (
      tester,
    ) async {
      final recording = Recording();
      await recording.start();
      await pumpBody(tester, errorView(surface: 'vehicle'));

      final records = await recording.stop();
      expect(
        records.singleWhere((r) => r['evt'] == 'error_view')['surface'],
        'vehicle',
      );
    });
  });

  group('EmptyStateView', () {
    testWidgets('a pull reaches the refresh indicator', (tester) async {
      var refreshed = false;
      await pumpBody(
        tester,
        RefreshIndicator(
          onRefresh: () async => refreshed = true,
          child: const EmptyStateView(
            message: 'No records yet.',
            icon: Icons.inbox,
          ),
        ),
      );

      await tester.fling(
        find.text('No records yet.'),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('not scrollable, it nests inside another list', (tester) async {
      await pumpBody(
        tester,
        ListView(
          children: const [
            EmptyStateView(
              message: 'No records yet.',
              icon: Icons.inbox,
              scrollable: false,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No records yet.'), findsOneWidget);
    });

    testWidgets('a rebuild does not repeat the record', (tester) async {
      final recording = Recording();
      await recording.start();
      for (var i = 0; i < 3; i++) {
        await pumpBody(
          tester,
          EmptyStateView(message: 'nothing here $i', icon: Icons.inbox),
        );
      }

      final records = await recording.stop();
      final empty = records.where((r) => r['evt'] == 'empty_view');
      expect(empty, hasLength(1));
      expect(empty.single['surface'], 'garage');
    });
  });
}
