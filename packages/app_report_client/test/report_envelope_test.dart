import 'dart:convert';

import 'package:app_report_client/app_report_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// The schema an application would pass in. Any number does here — what these
/// tests are about is which one comes back out, never what it means.
const schema = 1;

/// A log the way a recording actually produces one: header line, then records.
String logWith(Map<String, Object?> header, {int records = 1}) => [
      jsonEncode(header),
      for (var i = 0; i < records; i++)
        jsonEncode({'t': i, 'src': 'app', 'lvl': 'info'}),
      '',
    ].join('\n');

ReportEnvelope envelopeOf(String log) =>
    reportEnvelope(log, formatVersion: schema);

void main() {
  group('header', () {
    test('is taken from the log line, not from anything alongside it', () {
      final envelope = envelopeOf(
        logWith({
          'v': 1,
          'ts': '2026-07-31T10:00:00.000Z',
          'session': 'abc',
          'stream': 'ui',
          'app': '0.11.7+11700',
          'flavor': 'mobile',
          'os': 'Android 15',
          'scheme': 'https',
          'host_kind': 'name',
          'port': 443,
          'auth': 'apiKey',
        }),
      );

      expect(envelope.header['app'], '0.11.7+11700');
      expect(envelope.header['os'], 'Android 15');
      // A fingerprint arrives spread flat, as scalars the relay accepts rather
      // than as a nested object it refuses.
      expect(envelope.header['scheme'], 'https');
      expect(envelope.header['port'], 443);
    });

    test('is empty when the log starts with a record instead of a header', () {
      // A header write may fail silently while the writes after it succeed.
      // Reading that first record as a session header would put one event's
      // fields in the issue as though they described the whole recording.
      final envelope = envelopeOf('{"t":0,"src":"app","lvl":"info"}\n');
      expect(envelope.header, isEmpty);
      expect(envelope.logSchema, schema);
    });

    test('is empty for an unreadable or missing first line', () {
      expect(envelopeOf('').header, isEmpty);
      expect(envelopeOf('not json at all\n').header, isEmpty);
      expect(envelopeOf('[1,2,3]\n').header, isEmpty);
    });

    test('passes through what the relay would refuse, rather than repairing it',
        () {
      // The relay validates the header and is the authority on it. Reshaping it
      // here would mean the client quietly fixing headers the app should not be
      // producing — a bug that then never surfaces.
      final envelope = envelopeOf(
        logWith({
          'app': '0.11.7',
          'nested': {'no': 'objects'},
          'Bad-Key': 'dashes are not allowed',
          'long': 'x' * 400,
          'multiline': '1.2.5\nauth: none',
        }),
      );

      expect(envelope.header['nested'], {'no': 'objects'});
      expect(envelope.header['Bad-Key'], 'dashes are not allowed');
      expect((envelope.header['long']! as String).length, 400);
      expect(envelope.header['multiline'], contains('\n'));
    });

    test('drops nulls, which the map cannot hold anyway', () {
      final envelope = envelopeOf(logWith({'app': '0.11.7', 'device': null}));

      expect(envelope.header.keys, ['app']);
    });
  });

  group('schema', () {
    test('matches the version the log itself carries', () {
      expect(envelopeOf(logWith({'v': 1, 'app': '0.11.7'})).logSchema, 1);
    });

    test('reports an older recording under its own version, not this build', () {
      // A recording made before an update follows the schema it was written
      // with; whether that one is still accepted is the relay's decision.
      expect(envelopeOf(logWith({'v': 7, 'app': '0.9.0'})).logSchema, 7);
    });

    test('falls back to the build\'s own when the header does not say', () {
      expect(envelopeOf(logWith({'app': '0.11.7'})).logSchema, schema);
      expect(envelopeOf(logWith({'v': 0})).logSchema, schema);
      expect(envelopeOf(logWith({'v': 'one'})).logSchema, schema);
    });

    test('is whatever the application passed, not a number this package owns',
        () {
      // Schema numbers are per application — two applications at schema 1 are
      // two unrelated formats — so nothing here may assume one.
      expect(envelopeOf(logWith({'app': '0.9'}), ).logSchema, schema);
      expect(reportEnvelope(logWith({'app': '0.9'}), formatVersion: 4).logSchema,
          4);
    });
  });

  group('a request, which has no log to read a header off', () {
    test('carries the versions and the language, and nothing else', () {
      final envelope = requestEnvelope(
        formatVersion: schema,
        app: '0.11.7+11700',
        server: '0.2.5b3',
        locale: 'pl-PL',
        at: DateTime.utc(2026, 8, 9, 12),
      );

      expect(envelope.header['v'], schema);
      expect(envelope.header['app'], '0.11.7+11700');
      expect(envelope.header['server'], '0.2.5b3');
      expect(envelope.header['locale'], 'pl-PL');
      expect(envelope.header['ts'], '2026-08-09T12:00:00.000Z');
      // There is deliberately no way to pass the rest: a public issue about an
      // idea is no place for the reporter's phone, their server or how they
      // sign in, so the signature does not offer to carry them.
      expect(envelope.header.keys, unorderedEquals(
        ['v', 'ts', 'app', 'server', 'locale'],
      ));
    });

    test('claims no schema, because it attaches no log', () {
      expect(
        requestEnvelope(formatVersion: schema, app: '0.11.7').logSchema,
        isNull,
      );
    });

    test('leaves out what the session could not answer', () {
      // No server reached, no locale: sending an empty string would read as a
      // server that answered with nothing.
      final envelope =
          requestEnvelope(formatVersion: schema, app: '0.11.7+11700');

      expect(envelope.header.keys, unorderedEquals(['v', 'ts', 'app']));
    });

    test('only the bug kind carries a recording', () {
      expect(ReportKind.bug.needsLog, isTrue);
      expect(ReportKind.change.needsLog, isFalse);
      expect(ReportKind.feature.needsLog, isFalse);
      // Wire values: the relay opens a different issue for each name.
      expect(ReportKind.values.map((k) => k.name), ['bug', 'change', 'feature']);
    });
  });
}
