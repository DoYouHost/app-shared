import 'dart:typed_data';

import 'package:app_report_client/app_report_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every answer the relay can give, and what the user is told about it.
///
/// This is the whole contract between the two halves, and it is a contract of
/// status codes: the relay says 403 and the app has to know that means "wait",
/// not "this failed". Getting one wrong is silent — the report either sits in a
/// queue that will never drain, or is thrown away while the relay was still
/// willing to take it.
class _Answering implements HttpClientAdapter {
  _Answering(this.reply);

  /// A [ResponseBody] to answer, or a [DioException] to fail the way a dead
  /// network does.
  final Object Function(RequestOptions options) reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final answer = reply(options);
    if (answer is DioException) throw answer;
    return answer as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status, {Map<String, List<String>>? extra}) =>
    ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...?extra,
      },
    );

const base = 'https://relay.example/someapp';

RelayTicket usable() {
  final now = DateTime.now();
  return RelayTicket(
    ticket: 'signed',
    notBefore: now,
    expiresAt: now.add(const Duration(minutes: 30)),
    challenge: const PowChallenge(seed: 'seed', bits: 0),
    powNonce: '0',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RelayClient clientAnswering(Object Function(RequestOptions) reply) =>
      RelayClient(Dio()..httpClientAdapter = _Answering(reply), baseUrl: base);

  Future<RelayFailure> failureOfSend(Object Function(RequestOptions) reply) async {
    try {
      await clientAnswering(reply).send(
        installId: 'i',
        ticket: usable(),
        kind: ReportKind.bug,
        description: 'd',
        header: const {},
        logSchema: 1,
        log: 'line\n',
      );
    } on RelayException catch (e) {
      return e.failure;
    }
    fail('the send was expected to throw');
  }

  group('asking for a challenge', () {
    test('a 200 becomes a ticket with its window and its difficulty', () async {
      final nbf = DateTime.now().add(const Duration(seconds: 25));
      final exp = DateTime.now().add(const Duration(minutes: 30));
      final client = clientAnswering(
        (_) => _json(
          '{"ticket":"abc.def","nbf":${nbf.millisecondsSinceEpoch},'
          '"exp":${exp.millisecondsSinceEpoch},"seed":"a3f9","bits":12}',
          200,
        ),
      );

      final ticket = await client.challenge('install-1');

      expect(ticket.ticket, 'abc.def');
      expect(ticket.challenge.seed, 'a3f9');
      expect(ticket.challenge.bits, 12);
      // Not due yet, and the wait is what the countdown on screen is made of.
      expect(ticket.ready, isFalse);
      expect(ticket.expired, isFalse);
      expect(ticket.wait.inSeconds, inInclusiveRange(20, 25));
      // Nobody has solved it yet; the sender does that while the user writes.
      expect(ticket.powNonce, isNull);
    });

    test('it posts the install id and nothing else', () async {
      late RequestOptions seen;
      final client = clientAnswering((options) {
        seen = options;
        return _json('{"ticket":"t","nbf":0,"exp":0,"seed":"s","bits":0}', 200);
      });

      await client.challenge('11111111-1111-4111-8111-111111111111');

      expect(seen.uri.toString(), '$base/challenge');
      expect(seen.method, 'POST');
      expect((seen.data! as Map).keys, ['installId']);
    });

    test('a 503 means stop asking, and says for how long', () async {
      // The relay has shut the door on this installation, or the global breaker
      // is down. Retrying soon does not help, and the header says when it might.
      final client = clientAnswering(
        (_) => _json('{}', 503, extra: {
          'retry-after': ['120'],
        }),
      );

      await expectLater(
        client.challenge('i'),
        throwsA(
          isA<RelayException>()
              .having((e) => e.failure, 'failure', RelayFailure.refused)
              .having((e) => e.retryAfter, 'retryAfter',
                  const Duration(seconds: 120)),
        ),
      );
    });

    test('a 503 with no retry-after is still refused, just without a when',
        () async {
      final client = clientAnswering((_) => _json('{}', 503));

      await expectLater(
        client.challenge('i'),
        throwsA(isA<RelayException>()
            .having((e) => e.failure, 'failure', RelayFailure.refused)
            .having((e) => e.retryAfter, 'retryAfter', isNull)),
      );
    });

    test('anything else the relay says is our bug, not the user\'s', () async {
      for (final status in [400, 401, 404, 500]) {
        final client = clientAnswering((_) => _json('{}', status));
        await expectLater(
          client.challenge('i'),
          throwsA(isA<RelayException>()
              .having((e) => e.failure, 'failure', RelayFailure.rejected)),
          reason: 'status $status',
        );
      }
    });

    test('a network that never answers is unreachable, not rejected', () async {
      // The distinction the user acts on: one is worth a retry and the other is
      // worth reaching for GitHub's own form.
      final client = clientAnswering(
        (options) => DioException.connectionError(
          requestOptions: options,
          reason: 'Failed host lookup',
        ),
      );

      await expectLater(
        client.challenge('i'),
        throwsA(isA<RelayException>()
            .having((e) => e.failure, 'failure', RelayFailure.unreachable)),
      );
    });
  });

  group('sending the report', () {
    test('a 201 hands back the issue URL, which is the one unrecoverable bit',
        () async {
      final client = clientAnswering(
        (_) => _json('{"url":"https://github.example/issues/412"}', 201),
      );

      expect(
        await client.send(
          installId: 'i',
          ticket: usable(),
          kind: ReportKind.bug,
          description: 'd',
          header: const {'app': '0.11.7'},
          logSchema: 1,
          log: 'line\n',
        ),
        'https://github.example/issues/412',
      );
    });

    test('a 403 is "not yet", so the report is kept and retried', () async {
      // The ticket was not usable yet, or no longer. Reporting this as a failure
      // would throw away a report the relay would have taken a minute later.
      expect(await failureOfSend((_) => _json('{}', 403)), RelayFailure.notYet);
    });

    test('a 409 is "already reported", which nothing can retry into', () async {
      expect(
        await failureOfSend((_) => _json('{}', 409)),
        RelayFailure.duplicate,
      );
    });

    test('a 502 is the tracker being down, not the envelope being wrong',
        () async {
      expect(
        await failureOfSend((_) => _json('{}', 502)),
        RelayFailure.unreachable,
      );
    });

    test('a 400 is our envelope, and no amount of retrying fixes it', () async {
      expect(await failureOfSend((_) => _json('{}', 400)), RelayFailure.rejected);
      expect(await failureOfSend((_) => _json('{}', 422)), RelayFailure.rejected);
      expect(await failureOfSend((_) => _json('{}', 500)), RelayFailure.rejected);
    });

    test('a 200 is not a 201, and is treated as a rejection', () async {
      // The relay creates an issue or it does not; a 200 means it answered
      // something this client does not understand, and there is no URL in hand.
      expect(await failureOfSend((_) => _json('{"url":"x"}', 200)),
          RelayFailure.rejected);
    });

    test('a 503 while sending is worth waiting out, with its own delay',
        () async {
      final client = clientAnswering(
        (_) => _json('{}', 503, extra: {
          'retry-after': ['45'],
        }),
      );

      await expectLater(
        client.send(
          installId: 'i',
          ticket: usable(),
          kind: ReportKind.feature,
          description: 'd',
          header: const {},
        ),
        throwsA(isA<RelayException>()
            .having((e) => e.failure, 'failure', RelayFailure.notYet)
            .having((e) => e.retryAfter, 'retryAfter',
                const Duration(seconds: 45))),
      );
    });

    test('a retry-after that is not a number is no retry-after at all',
        () async {
      // HTTP allows a date there. Parsing it as seconds would schedule the
      // retry for whenever `int.tryParse` felt like, so it is dropped instead.
      final client = clientAnswering(
        (_) => _json('{}', 503, extra: {
          'retry-after': ['Wed, 09 Aug 2026 12:00:00 GMT'],
        }),
      );

      await expectLater(
        client.send(
          installId: 'i',
          ticket: usable(),
          kind: ReportKind.bug,
          description: 'd',
          header: const {},
          logSchema: 1,
          log: 'x\n',
        ),
        throwsA(isA<RelayException>()
            .having((e) => e.retryAfter, 'retryAfter', isNull)),
      );
    });
  });

  group('which failures the sender may retry', () {
    test('only the two that describe a door that might open', () {
      // `retryable` is what decides whether a report stays in the outbox. A
      // wrong answer here either loses the report or retries it forever.
      const retryable = {RelayFailure.notYet, RelayFailure.unreachable};

      for (final failure in RelayFailure.values) {
        expect(
          RelayException(failure).retryable,
          retryable.contains(failure),
          reason: failure.name,
        );
      }
    });
  });

  group('the ticket the app holds on to', () {
    test('it knows when it is due, and when it is past saving', () {
      final now = DateTime.now();
      final future = RelayTicket(
        ticket: 't',
        notBefore: now.add(const Duration(minutes: 2)),
        expiresAt: now.add(const Duration(minutes: 30)),
        challenge: const PowChallenge(seed: 's', bits: 0),
      );
      final stale = RelayTicket(
        ticket: 't',
        notBefore: now.subtract(const Duration(hours: 2)),
        expiresAt: now.subtract(const Duration(hours: 1)),
        challenge: const PowChallenge(seed: 's', bits: 0),
      );

      expect(future.ready, isFalse);
      expect(future.expired, isFalse);
      expect(future.wait.inSeconds, inInclusiveRange(115, 120));

      expect(stale.ready, isTrue, reason: 'due long ago');
      expect(stale.expired, isTrue);
      // Never negative: it drives a countdown, and a negative one would render.
      expect(stale.wait, Duration.zero);
    });

    test('solving it changes the nonce and nothing else', () {
      final before = usable();
      final after = before.solved('987654');

      expect(after.powNonce, '987654');
      expect(after.ticket, before.ticket);
      expect(after.notBefore, before.notBefore);
      expect(after.expiresAt, before.expiresAt);
      expect(after.challenge.seed, before.challenge.seed);
      expect(after.challenge.bits, before.challenge.bits);
    });

    test('an unsolved ticket carries no nonce field at all on disk', () {
      // The outbox reads it back; a null under the key would deserialise fine
      // but says "solved to nothing" to anyone reading the file.
      expect(
        RelayTicket(
          ticket: 't',
          notBefore: DateTime.now(),
          expiresAt: DateTime.now(),
          challenge: const PowChallenge(seed: 's', bits: 1),
        ).toJson().keys,
        isNot(contains('powNonce')),
      );
    });
  });
}
