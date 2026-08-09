import 'dart:convert';
import 'dart:io';

import 'package:app_report_client/app_report_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// The outbox against a real directory.
///
/// Everything here is about the promise the send flow makes to the user: they
/// tapped send, so the report is theirs now and has to survive the screen
/// closing, the app being backgrounded, and the process being killed. A fake
/// filesystem would test the code; these test the promise.
RelayTicket ticket({Duration wait = Duration.zero, String id = 'signed'}) {
  final now = DateTime.now();
  return RelayTicket(
    ticket: id,
    notBefore: now.add(wait),
    expiresAt: now.add(wait + const Duration(minutes: 30)),
    challenge: const PowChallenge(seed: 'seed', bits: 4),
  );
}

void main() {
  late Directory root;
  late ReportOutbox outbox;

  setUp(() {
    root = Directory.systemTemp.createTempSync('outbox_test');
    outbox = ReportOutbox(root: root);
  });
  tearDown(() => root.deleteSync(recursive: true));

  File slot() => File('${root.path}/outbox/pending.json');

  Future<PendingReport> putBug({
    String id = 'r1',
    String log = '{"v":1,"app":"0.11.7"}\n{"t":1}\n',
  }) =>
      outbox.put(
        id: id,
        kind: ReportKind.bug,
        description: 'kolejka pusta po wznowieniu',
        header: const {'v': 1, 'app': '0.11.7+1107000'},
        logSchema: 1,
        ticket: ticket(),
        log: log,
      );

  group('surviving the process', () {
    test('a queued bug report reads back whole from a cold instance', () async {
      await putBug();

      // A different object over the same directory, as after a restart: nothing
      // may be held in memory for this to work.
      final reopened = await ReportOutbox(root: root).peek();

      expect(reopened, isNotNull);
      expect(reopened!.id, 'r1');
      expect(reopened.kind, ReportKind.bug);
      expect(reopened.description, 'kolejka pusta po wznowieniu');
      expect(reopened.header, {'v': 1, 'app': '0.11.7+1107000'});
      expect(reopened.logSchema, 1);
      expect(reopened.hasLog, isTrue);
      expect(
        await ReportOutbox(root: root).readLog(reopened),
        '{"v":1,"app":"0.11.7"}\n{"t":1}\n',
      );
    });

    test('the ticket survives with the not-before that makes it wait', () async {
      final issued = ticket(wait: const Duration(minutes: 5), id: 'abc.def');
      await outbox.put(
        id: 'r2',
        kind: ReportKind.bug,
        description: 'x',
        header: const {},
        logSchema: 1,
        ticket: issued,
        log: 'line\n',
      );

      final back = (await ReportOutbox(root: root).peek())!.ticket;

      // Round-tripped through epoch milliseconds, so equality is to the
      // millisecond rather than to the microsecond the clock had.
      expect(back.ticket, 'abc.def');
      expect(back.notBefore.millisecondsSinceEpoch,
          issued.notBefore.millisecondsSinceEpoch);
      expect(back.challenge.seed, 'seed');
      expect(back.challenge.bits, 4);
      expect(back.ready, isFalse);
      expect(back.expired, isFalse);
      expect(back.wait.inMinutes, closeTo(4, 1));
    });

    test('a solved proof of work is not re-solved after a restart', () async {
      // Solving is about a second of hashing. Losing it across a restart would
      // spend that second on the send instead, which is where there is none.
      await outbox.put(
        id: 'r3',
        kind: ReportKind.change,
        description: 'x',
        header: const {},
        ticket: ticket().solved('12345'),
      );

      expect((await ReportOutbox(root: root).peek())!.ticket.powNonce, '12345');
    });

    test('a request keeps no log file to clean up after', () async {
      await outbox.put(
        id: 'r4',
        kind: ReportKind.feature,
        description: 'harmonogram wydruków',
        header: const {'app': '0.11.7'},
        ticket: ticket(),
      );

      final back = (await ReportOutbox(root: root).peek())!;
      expect(back.kind, ReportKind.feature);
      expect(back.hasLog, isFalse);
      expect(back.logSchema, isNull);
      expect(await outbox.readLog(back), isNull);
      // Only the slot itself is on disk.
      expect(
        Directory('${root.path}/outbox').listSync().map((e) => e.path.split('/').last),
        ['pending.json'],
      );
    });

    test('a twenty-megabyte log lives beside the slot, not inside it', () async {
      // A recording reaches the size ceiling; a JSON blob that big would be
      // parsed on every peek, including the one at app start.
      final big = '${'x' * (1024 * 1024)}\n';
      await putBug(log: big);

      expect(slot().lengthSync(), lessThan(2000));
      expect(await outbox.readLog((await outbox.peek())!), big);
    });
  });

  group('one slot, deliberately', () {
    test('a second report replaces the first rather than queueing behind it',
        () async {
      // A queue that can grow is a queue that can hold a stale log nobody
      // remembers writing.
      await putBug(id: 'first');
      await outbox.put(
        id: 'second',
        kind: ReportKind.change,
        description: 'nowsze',
        header: const {},
        ticket: ticket(),
      );

      expect((await outbox.peek())!.id, 'second');
    });

    test('clearing takes the log file with it, not just the slot', () async {
      final report = await putBug();
      expect(File(report.logPath!).existsSync(), isTrue);

      await outbox.clear();

      expect(await outbox.peek(), isNull);
      expect(File(report.logPath!).existsSync(), isFalse);
      expect(slot().existsSync(), isFalse);
    });
  });

  group('what a half-dead process leaves behind', () {
    test('a slot pointing at a log that is gone is dropped, not retried',
        () async {
      // It would fail on every retry forever, and the failure the user sees
      // says nothing about a file.
      final report = await putBug();
      File(report.logPath!).deleteSync();

      expect(await outbox.peek(), isNull);
      // And the slot goes too, so the next start finds a clean outbox.
      expect(slot().existsSync(), isFalse);
    });

    test('a slot half-written by a process that died mid-save is dropped',
        () async {
      await putBug();
      final text = slot().readAsStringSync();
      slot().writeAsStringSync(text.substring(0, text.length ~/ 2));

      expect(await outbox.peek(), isNull);
      expect(slot().existsSync(), isFalse);
    });

    test('an empty outbox directory is simply empty', () async {
      expect(await outbox.peek(), isNull);
      // And clearing one that was never written does not throw.
      await outbox.clear();
      expect(await outbox.peek(), isNull);
    });
  });

  group('a slot written by an older build', () {
    test('one with no kind at all is read as the bug it must have been',
        () async {
      // Exactly what an install upgrading mid-wait has sitting in its outbox:
      // the report is the user's and still sendable, so it is read rather than
      // thrown away.
      final report = await putBug(id: 'old');
      slot().writeAsStringSync(
        slot().readAsStringSync().replaceFirst('"kind":"bug",', ''),
      );

      final back = (await ReportOutbox(root: root).peek())!;
      expect(back.kind, ReportKind.bug);
      expect(back.logPath, report.logPath);
      expect(back.description, 'kolejka pusta po wznowieniu');
    });

    test('one naming a kind this build has never heard of is read as a bug',
        () async {
      // The other direction: a downgrade, or a build that shipped a kind later
      // dropped. Guessing bug keeps the report; refusing it loses one.
      await putBug(id: 'future');
      slot().writeAsStringSync(
        slot().readAsStringSync().replaceFirst('"kind":"bug"', '"kind":"rant"'),
      );

      expect((await ReportOutbox(root: root).peek())!.kind, ReportKind.bug);
    });

    test('the slot on disk is the shape older builds already write', () async {
      // A rename here strands a queued report on every install that updates
      // mid-wait, and the failure is silent.
      await putBug(id: 'shape');
      final json = jsonDecode(slot().readAsStringSync()) as Map<String, dynamic>;

      expect(
        json.keys,
        containsAll(['id', 'kind', 'description', 'header', 'ticket', 'logPath']),
      );
      expect(
        (json['ticket'] as Map).keys,
        containsAll(['ticket', 'notBefore', 'expiresAt', 'seed', 'bits']),
      );
      expect(json['logSchema'], 1);
    });
  });
}
