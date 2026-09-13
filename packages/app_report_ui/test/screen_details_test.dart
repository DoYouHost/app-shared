import 'dart:io';

import 'package:app_report_client/app_report_client.dart';
import 'package:app_report_ui/app_report_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late ReportLocalizations l10n;

  setUpAll(() async {
    l10n = await ReportLocalizations.delegate.load(const Locale('pl'));
  });

  Future<ProviderContainer> pump(WidgetTester tester, Rig rig) async {
    final container = rig.container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: plApp(const BugReportScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  group('a report on its way out', () {
    // The countdown ticks every second, so these pump frames by hand and end on
    // an idle state rather than settling on a timer that never stops.
    Future<void> show(WidgetTester tester) async {
      await tester.pump();
      await tester.pump();
    }

    testWidgets('one of the kind on screen needs no explaining', (
      tester,
    ) async {
      final sender = ScriptedSender();
      await pump(tester, Rig(sender: sender));

      sender.emit(
        SendState.waiting(DateTime.now().add(const Duration(minutes: 2))),
      );
      await show(tester);

      expect(find.text(l10n.bugReportSendWaitingBody), findsOneWidget);
      expect(find.text(l10n.bugReportQueuedBug), findsNothing);

      await tester.tap(find.text(l10n.bugReportCancelSend));
      await show(tester);
      expect(find.text(l10n.bugReportSendWaitingBody), findsNothing);
    });

    testWidgets('one seen from another tab names its report', (tester) async {
      // A bug report still waiting would otherwise read as the request being
      // typed having gone out already.
      final sender = ScriptedSender();
      await pump(tester, Rig(sender: sender));
      await tester.tap(find.text(l10n.bugReportKindChange));
      await tester.pumpAndSettle();

      sender.emit(
        SendState.waiting(
          DateTime.now().add(const Duration(minutes: 2)),
          kind: ReportKind.feature,
        ),
      );
      await show(tester);

      expect(find.text(l10n.bugReportQueuedFeature), findsOneWidget);

      sender.emit(const SendState.idle());
      await show(tester);
    });
  });

  testWidgets('the review shows what describes the session, not the file', (
    tester,
  ) async {
    final container = await pump(tester, Rig());
    final controller = container.read(bugReportProvider.notifier);
    await controller.start();
    await controller.stop();
    await tester.pumpAndSettle();

    // The screen before this one promises the phone and the server's version
    // are in the log, and the header is the only place they are.
    expect(find.textContaining('app 0.11.2+1102'), findsOneWidget);
    expect(find.textContaining('os Android 15'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\bstream \w')), findsNothing);
    expect(find.textContaining(RegExp(r'\bts \d')), findsNothing);
  });

  testWidgets('a record from another isolate says which', (tester) async {
    // Only a background isolate writes `iso`, and its records only exist on
    // disk — so the review is reached the way a crashed session reaches it.
    final dir = Directory.systemTemp.createTempSync('report_iso');
    addTearDown(() => dir.deleteSync(recursive: true));
    const session = 'feedfacefeedfacefeedfacefeedface';
    File('${dir.path}/session-$session.jsonl').writeAsStringSync(
      '{"v":1,"ts":"2026-07-26T12:00:00.000Z","session":"$session",'
      '"stream":"ui","app":"1"}\n'
      '{"t":5,"src":"app","evt":"poll","iso":"bg"}\n'
      '{"t":6,"src":"ui","evt":"tap"}\n',
    );
    final container = Rig(
      orphanSession: session,
      logDirectory: dir,
    ).container();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: plApp(const BugReportScreen()),
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (container.read(bugReportProvider).recovered == null &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    container.read(bugReportProvider.notifier).showRecovered();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ui · tap'), 200);

    expect(find.text('app · poll · bg'), findsOneWidget);
    expect(find.text('ui · tap'), findsOneWidget);
  });

  testWidgets('a tablet-wide screen is capped when the app asks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester, Rig(maxContentWidth: 600));

    expect(tester.getSize(find.byType(ListView)).width, 600);
  });
}
