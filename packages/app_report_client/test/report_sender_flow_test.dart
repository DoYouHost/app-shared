import 'dart:async';
import 'dart:io';

import 'package:app_report_client/app_report_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sender's behaviour around the things that actually go wrong: a slow
/// challenge, a user changing their mind, a log that disappears under it, and a
/// queued report the app is told about only after a restart.
///
/// Separate from `report_sender_test.dart`, which covers the happy path and the
/// wire shape. What is here is the set of behaviours that were reasoned about
/// and asserted nowhere — every one of these was believed to hold before it was
/// checked, and two of them did not.

RelayTicket ticket({Duration wait = Duration.zero, Duration life = const Duration(minutes: 30)}) {
  final now = DateTime.now();
  return RelayTicket(
    ticket: 'signed',
    notBefore: now.add(wait),
    expiresAt: now.add(wait + life),
    challenge: const PowChallenge(seed: 'seed', bits: 0),
  );
}

class _Relay extends RelayClient {
  _Relay({this.issued, this.gate, this.onSend})
      : super(Dio(), baseUrl: 'https://relay.example/someapp');

  RelayTicket? issued;

  /// Held open by the tests that need a second call made while the first is
  /// still in flight.
  Future<void>? gate;
  Future<String> Function()? onSend;

  int challenges = 0;
  int sends = 0;
  final kinds = <ReportKind>[];

  @override
  Future<RelayTicket> challenge(String installId) async {
    challenges++;
    await gate;
    final next = issued;
    if (next == null) throw const RelayException(RelayFailure.unreachable);
    return next;
  }

  @override
  Future<String> send({
    required String installId,
    required RelayTicket ticket,
    required ReportKind kind,
    required String description,
    required Map<String, Object> header,
    int? logSchema,
    String? log,
  }) async {
    sends++;
    kinds.add(kind);
    final handler = onSend;
    if (handler != null) return await handler();
    return 'https://github.example/issues/1';
  }
}

/// An outbox whose log vanishes between the peek and the read.
///
/// That window is the only way into the "should have a log and has not" branch:
/// [ReportOutbox.peek] already drops a slot pointing at a missing file, so the
/// guard downstream can only be reached by a delete landing in between. Narrow,
/// but it is the branch that decides whether a doomed slot is dropped or handed
/// to every later start to retry forever.
class _VanishingLog extends ReportOutbox {
  _VanishingLog(Directory root) : super(root: root);

  @override
  Future<String?> readLog(PendingReport report) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('sender_flow'));
  tearDown(() => root.deleteSync(recursive: true));

  ReportSender senderWith(
    _Relay relay, {
    ReportOutbox? outbox,
    bool demo = false,
  }) =>
      ReportSender(
        client: relay,
        outbox: outbox ?? ReportOutbox(root: root),
        installId: () async => 'install-1',
        demoMode: () => demo,
        formatVersion: 1,
      );

  Future<void> submitBug(ReportSender sender) => sender.submit(
        description: 'kolejka pusta po wznowieniu',
        log: '{"v":1,"app":"0.11.7"}\n{"t":1}\n',
      );

  Future<void> submitRequest(ReportSender sender, ReportKind kind) =>
      sender.submitRequest(
        kind: kind,
        description: 'harmonogram wydruków',
        envelope: requestEnvelope(formatVersion: 1, app: '0.11.7+1107000'),
      );

  group('paying for a challenge exactly once', () {
    test('a second call while the first is in flight joins it', () async {
      // The check for a ticket already held cannot see one that has not arrived
      // yet, so without joining, a user typing four characters over a slow
      // connection buys four challenges — and each one doubles their next wait.
      final gate = Completer<void>();
      final relay = _Relay(issued: ticket(), gate: gate.future);
      final sender = senderWith(relay);
      addTearDown(sender.dispose);

      final calls = [
        sender.prepare(),
        sender.prepare(),
        sender.prepare(),
        sender.prepare(),
      ];
      gate.complete();
      await Future.wait(calls);

      expect(relay.challenges, 1);
    });

    test('a call after the first finished reuses the ticket it bought',
        () async {
      final relay = _Relay(issued: ticket());
      final sender = senderWith(relay);
      addTearDown(sender.dispose);

      await sender.prepare();
      await sender.prepare();
      await sender.prepare();

      expect(relay.challenges, 1);
    });

    test('a failed attempt does not poison the next one', () async {
      // The memo has to clear on failure too, or an unreachable relay at the
      // wrong moment would leave the app unable to ever ask again.
      final relay = _Relay();
      final sender = senderWith(relay);
      addTearDown(sender.dispose);

      await sender.prepare();
      expect(relay.challenges, 1);

      relay.issued = ticket();
      await sender.prepare();

      expect(relay.challenges, 2);
      // And it really has one now: the report goes out rather than failing.
      await submitBug(sender);
      expect(relay.sends, 1);
    });

    test('an expired ticket is replaced rather than reused', () async {
      final relay = _Relay(
        issued: ticket(life: const Duration(milliseconds: -1)),
      );
      final sender = senderWith(relay);
      addTearDown(sender.dispose);

      await sender.prepare();
      relay.issued = ticket();
      await sender.prepare();

      expect(relay.challenges, 2);
    });
  });

  group('what the screen is told', () {
    test('the kind travels with every state, not with the screen', () async {
      // The user can switch tabs while a report waits out its delay. If the
      // state did not carry its own kind, the countdown and the failure advice
      // would describe whichever tab happened to be open.
      final relay = _Relay(issued: ticket(wait: const Duration(minutes: 5)));
      final sender = senderWith(relay);
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.prepare();
      await submitRequest(sender, ReportKind.feature);
      await pumpEventQueue();

      expect(seen.last.phase, SendPhase.waiting);
      expect(seen.last.kind, ReportKind.feature);
      expect(seen.last.readyAt, isNotNull);
      expect(seen.last.remaining.inMinutes, closeTo(4, 1));
    });

    test('a failure names the kind that failed', () async {
      final relay = _Relay(
        issued: ticket(),
        onSend: () async => throw const RelayException(RelayFailure.duplicate),
      );
      final sender = senderWith(relay);
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.prepare();
      await submitRequest(sender, ReportKind.change);
      await pumpEventQueue();

      expect(seen.last.phase, SendPhase.failed);
      expect(seen.last.failure, RelayFailure.duplicate);
      expect(seen.last.kind, ReportKind.change);
    });

    test('a report queued yesterday is announced under its own kind', () async {
      // Nothing in this process chose that kind — it comes off disk, and the
      // screen has never seen the report before.
      await ReportOutbox(root: root).put(
        id: 'yesterday',
        kind: ReportKind.feature,
        description: 'z wczoraj',
        header: const {'app': '0.11.7'},
        ticket: ticket(wait: const Duration(minutes: 5)),
      );

      final relay = _Relay(issued: ticket());
      final sender = senderWith(relay);
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.flush();
      await pumpEventQueue();

      expect(seen.last.phase, SendPhase.waiting);
      expect(seen.last.kind, ReportKind.feature);
      expect(relay.sends, 0);
    });

    test('the sent state carries the URL and the kind together', () async {
      final relay = _Relay(issued: ticket());
      final sender = senderWith(relay);
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.prepare();
      await submitBug(sender);
      await pumpEventQueue();

      expect(seen.last.phase, SendPhase.sent);
      expect(seen.last.issueUrl, 'https://github.example/issues/1');
      expect(seen.last.kind, ReportKind.bug);
      expect(relay.kinds, [ReportKind.bug]);
    });
  });

  group('a log that went missing under us', () {
    test('the doomed slot is dropped instead of retried forever', () async {
      // A description with no log would be filed as something the user did not
      // write, and keeping the slot hands the same dead end to every later
      // start.
      final outbox = _VanishingLog(root);
      final relay = _Relay(issued: ticket());
      final sender = senderWith(relay, outbox: outbox);
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.prepare();
      await submitBug(sender);
      await pumpEventQueue();

      expect(relay.sends, 0);
      expect(seen.last.phase, SendPhase.failed);
      expect(seen.last.failure, RelayFailure.rejected);
      expect(await ReportOutbox(root: root).peek(), isNull);
    });

    test('the same holds on the path where the ticket had also expired',
        () async {
      // The other branch, and the one that kept the slot until today: a report
      // whose wait was outlived *and* whose log is gone.
      await ReportOutbox(root: root).put(
        id: 'stale',
        kind: ReportKind.bug,
        description: 'stale',
        header: const {},
        logSchema: 1,
        ticket: ticket(life: const Duration(milliseconds: -1)),
        log: 'line\n',
      );

      final relay = _Relay(issued: ticket());
      final sender = senderWith(relay, outbox: _VanishingLog(root));
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.flush();
      await pumpEventQueue();

      expect(relay.sends, 0);
      expect(seen.last.failure, RelayFailure.rejected);
      expect(await ReportOutbox(root: root).peek(), isNull);
    });

    test('a request has no log to lose, and is unaffected', () async {
      // `hasLog` is what tells "never had one" from "had one and lost it"; a
      // check on the log alone would refuse every request ever queued.
      final relay = _Relay(issued: ticket());
      final sender = senderWith(relay, outbox: _VanishingLog(root));
      addTearDown(sender.dispose);

      await sender.prepare();
      await submitRequest(sender, ReportKind.feature);
      await pumpEventQueue();

      expect(relay.sends, 1);
      expect(relay.kinds, [ReportKind.feature]);
    });
  });

  group('changing your mind', () {
    test('cancelling stops the send before the first await', () async {
      // The UI does not wait for this — a discard that blocks on storage is a
      // discard that sits there spinning — so everything that actually stops
      // the send has to be done by the time `cancel` returns its future.
      final relay = _Relay(issued: ticket(wait: const Duration(minutes: 5)));
      final sender = senderWith(relay);
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.prepare();
      await submitBug(sender);
      final cancelling = sender.cancel();
      await pumpEventQueue();

      // Idle already, without anybody awaiting the delete.
      expect(seen.last.phase, SendPhase.idle);
      await cancelling;
      expect(await ReportOutbox(root: root).peek(), isNull);
      expect(relay.sends, 0);
    });

    test('cancelling an empty outbox is a no-op, not a crash', () async {
      final sender = senderWith(_Relay(issued: ticket()));
      addTearDown(sender.dispose);

      await sender.cancel();

      expect(await ReportOutbox(root: root).peek(), isNull);
    });

    test('a flush after a cancel finds nothing and says so once', () async {
      final relay = _Relay(issued: ticket(wait: const Duration(minutes: 5)));
      final sender = senderWith(relay);
      addTearDown(sender.dispose);

      await sender.prepare();
      await submitBug(sender);
      await sender.cancel();
      await sender.flush();
      await pumpEventQueue();

      expect(relay.sends, 0);
    });
  });

  group('an outbox that cannot be read at all', () {
    test('app start survives a storage directory that will not resolve',
        () async {
      // `flush` runs at startup, in a future nobody awaits. A throw there takes
      // out the recording bar that wraps every screen.
      final relay = _Relay(issued: ticket());
      final sender = senderWith(relay, outbox: _ThrowingOutbox());
      addTearDown(sender.dispose);
      final seen = <SendState>[];
      sender.states.listen(seen.add);

      await sender.flush();
      await pumpEventQueue();

      expect(seen.last.phase, SendPhase.idle);
      expect(relay.sends, 0);
    });
  });
}

/// Storage that refuses to answer, the way an unresolvable support directory
/// does on a device with no writable storage left.
class _ThrowingOutbox extends ReportOutbox {
  const _ThrowingOutbox();

  @override
  Future<PendingReport?> peek() async => throw const FileSystemException('nope');
}
