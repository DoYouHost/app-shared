import 'dart:convert';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogHeader', () {
    test('encodes the session-wide fields, skipping absent ones', () {
      final header = LogHeader(
        ts: DateTime.utc(2026, 7, 25, 12, 4, 11),
        session: 'abc123',
        app: '0.11.2+1102',
        os: 'Android 15',
        locale: 'pl',
        extra: const {'flavor': 'mobile', 'device': 'Pixel 8'},
      );

      final json = jsonDecode(header.toJsonLine()) as Map<String, dynamic>;

      expect(json['v'], 1);
      expect(json['ts'], '2026-07-25T12:04:11.000Z');
      expect(json['session'], 'abc123');
      expect(json['stream'], 'ui');
      expect(json['app'], '0.11.2+1102');
      expect(json['os'], 'Android 15');
      // An application's own fields are flat top-level keys, not a nested
      // object: this is the whole reason `extra` can carry what used to be
      // declared fields without moving a byte of meaning on the wire.
      expect(json['flavor'], 'mobile');
      expect(json['device'], 'Pixel 8');
      expect(json.containsKey('server'), isFalse);
      expect(json.containsKey('auth'), isFalse);
    });

    test('local timestamps are normalised to UTC', () {
      final header = LogHeader(
        ts: DateTime(2026, 7, 25, 12),
        session: 's',
        app: '1.0.0+1',
      );

      expect(header.toJson()['ts'], endsWith('Z'));
    });

    test('session ids are 32 hex chars and unique', () {
      final ids = {for (var i = 0; i < 50; i++) LogHeader.newSessionId()};

      expect(ids, hasLength(50));
      expect(ids.every((id) => RegExp(r'^[0-9a-f]{32}$').hasMatch(id)), isTrue);
    });

    test('carries the server url shape, never the url', () {
      final header = LogHeader(
        ts: DateTime.utc(2026),
        session: 's',
        app: '1.0.0+1',
        serverUrl: ServerFingerprint.tryParse('https://bambuddy.local:8443'),
      );

      final json = header.toJson();
      expect(json['scheme'], 'https');
      expect(json['host_kind'], 'name');
      expect(json['port'], 8443);
      expect(header.toJsonLine(), isNot(contains('bambuddy.local')));
    });

    group('an application\'s own fields', () {
      test('survive a round trip through the line', () {
        // The reason `extra` can hold what used to be declared fields: what
        // goes out flat comes back whole, so a background isolate continuing
        // the UI's header does not quietly drop the app's half of it.
        final header = LogHeader(
          ts: DateTime.utc(2026),
          session: 's',
          app: '1.0.0+1',
          extra: const {'flavor': 'wear', 'auth': 'jwt', 'demo': true},
        );

        final read = LogHeader.tryParse(header.toJsonLine(), session: 's')!;

        expect(read.extra, {'flavor': 'wear', 'auth': 'jwt', 'demo': true});
      });

      test('cannot overwrite a field the header owns', () {
        // `extra` is the application's half of the line, and an app that names
        // a key this class already writes would otherwise decide what `app` or
        // `session` says.
        final header = LogHeader(
          ts: DateTime.utc(2026),
          session: 's',
          app: '1.0.0+1',
          extra: const {'app': 'not-the-version', 'session': 'not-the-id'},
        );

        final json = jsonDecode(header.toJsonLine()) as Map<String, dynamic>;

        expect(json['app'], '1.0.0+1');
        expect(json['session'], 's');
      });

      test('a line with none of them reads back as an empty map', () {
        final header = LogHeader(
          ts: DateTime.utc(2026),
          session: 's',
          app: '1',
        );

        final read = LogHeader.tryParse(header.toJsonLine(), session: 's')!;

        expect(read.extra, isEmpty);
      });
    });

    test('fgs stream is marked in the header', () {
      final header = LogHeader(
        ts: DateTime.utc(2026),
        session: 's',
        app: '1.0.0+1',
        stream: LogStream.fgs,
      );

      expect(header.toJson()['stream'], 'fgs');
    });
  });

  group('ServerFingerprint', () {
    test('tells a bare IP apart from a name', () {
      expect(
        ServerFingerprint.tryParse('http://192.168.1.9:8080')!.hostKind,
        HostKind.ip,
      );
      expect(
        ServerFingerprint.tryParse('https://bambuddy.example.com')!.hostKind,
        HostKind.name,
      );
    });

    test('fills in the default port when the url omits it', () {
      expect(ServerFingerprint.tryParse('https://host.example.com')!.port, 443);
      expect(ServerFingerprint.tryParse('http://host.example.com')!.port, 80);
    });

    test('returns null for anything it cannot parse', () {
      expect(ServerFingerprint.tryParse(null), isNull);
      expect(ServerFingerprint.tryParse(''), isNull);
      expect(ServerFingerprint.tryParse('nonsense'), isNull);
    });
  });

  group('LogEvent', () {
    test('spreads extra fields flat next to the record keys', () {
      final event = LogEvent(
        t: 1843,
        src: LogSource.http,
        evt: 'response',
        lvl: LogLevel.warn,
        fields: const {'method': 'GET', 'status': 502, 'ms': 1204},
      );

      expect(jsonDecode(event.toJsonLine()), {
        't': 1843,
        'src': 'http',
        'lvl': 'warn',
        'evt': 'response',
        'method': 'GET',
        'status': 502,
        'ms': 1204,
      });
    });

    test('omits the level when it is the default info', () {
      final event = LogEvent(t: 0, src: LogSource.ui, evt: 'route');

      expect(
        (jsonDecode(event.toJsonLine()) as Map).containsKey('lvl'),
        isFalse,
      );
    });

    test('drops null fields so call sites can pass optionals blindly', () {
      final event = LogEvent(
        t: 0,
        src: LogSource.ws,
        evt: 'disconnect',
        fields: const {'code': 1006, 'reason': null},
      );

      expect(event.fields, {'code': 1006});
    });

    test(
      'drops reserved keys instead of letting them overwrite the record',
      () {
        final event = LogEvent(
          t: 5,
          src: LogSource.app,
          evt: 'real',
          fields: const {'evt': 'spoofed', 't': 999, 'ok': true},
        );

        final json = jsonDecode(event.toJsonLine()) as Map<String, dynamic>;
        expect(json['evt'], 'real');
        expect(json['t'], 5);
        expect(json['ok'], isTrue);
      },
    );

    test('every record encodes to a single line', () {
      final event = LogEvent(
        t: 0,
        src: LogSource.err,
        evt: 'uncaught',
        lvl: LogLevel.error,
        fields: const {'stack': 'frame one\nframe two\nframe three'},
      );

      expect(event.toJsonLine(), isNot(contains('\n')));
    });
  });
}
