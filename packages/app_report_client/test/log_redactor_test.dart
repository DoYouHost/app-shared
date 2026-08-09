import 'package:app_report_client/app_report_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// The floor every application gets, tested without any application's rules.
///
/// Each app keeps its own suite for its own patterns — a Bambu serial and a
/// LubeLogger plate are neither of them this package's business. What is tested
/// here is what a new application inherits by writing one line of wiring, and
/// therefore what it is entitled to assume it does not have to think about.
void main() {
  late LogRedactor redactor;

  setUp(() => redactor = LogRedactor(ourKeys: {'id': RegExp(r'^\w+(\.\w+)*$')}));

  group('the baseline nobody has to configure', () {
    test('masks the host but keeps the scheme and the port', () {
      // What the user picked is half the diagnosis; the address is theirs.
      expect(
        redactor.scrubString('GET http://nas.example:8080/api/v1/queue/'),
        'GET http://[HOST]:8080/api/v1/queue/',
      );
      expect(redactor.scrubString('wss://cam.lan/stream'), 'wss://[HOST]/stream');
    });

    test('masks credentials in a URL rather than the whole URL', () {
      expect(
        redactor.scrubString('https://bob:hunter2@srv.lan/x'),
        'https://[CREDENTIALS]@[HOST]/x',
      );
    });

    test('masks a JWT, an e-mail, an IP and a token in a query', () {
      expect(
        redactor.scrubString('Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.sig'),
        'Bearer [JWT]',
      );
      expect(redactor.scrubString('user ala@example.com'), 'user [EMAIL]');
      expect(redactor.scrubString('dial 192.168.1.44:80'), 'dial [IP]:80');
      expect(
        redactor.scrubString('/x?token=abc123&page=2'),
        '/x?token=[REDACTED]&page=2',
      );
    });

    test('leaves a version number alone, which is not an IP', () {
      // Leading-zero octets are what tells a firmware version from an address.
      expect(redactor.scrubString('01.09.01.00'), '01.09.01.00');
    });

    test('redacts a secret-named field whatever its value looks like', () {
      final out = redactor.scrubFields({
        'api_key': 'not-obviously-a-secret',
        'x-api-key': 'nor this',
        'password': 'hunter2',
        'username': 'ala',
        'monkey': 'kept',
        'keyboard': 'kept',
      });

      expect(out['api_key'], '[REDACTED]');
      expect(out['x-api-key'], '[REDACTED]');
      expect(out['password'], '[REDACTED]');
      expect(out['username'], '[REDACTED]');
      // Fencing: neither of these is anybody's secret, and blanking them would
      // cost a diagnosis for nothing.
      expect(out['monkey'], 'kept');
      expect(out['keyboard'], 'kept');
    });

    test('keeps an absent value absent rather than calling it redacted', () {
      // Whether a field is set at all is often the diagnosis; `[REDACTED]` on a
      // null reads as "configured" and sends the next reader somewhere else.
      expect(redactor.scrubFields({'token': null})['token'], isNull);
    });

    test('reaches into nested maps and lists', () {
      final out = redactor.scrubFields({
        'body': {
          'items': [
            {'password': 'x', 'url': 'http://nas.lan/a'},
          ],
        },
      });

      final item = ((out['body']! as Map)['items']! as List).single as Map;
      expect(item['password'], '[REDACTED]');
      expect(item['url'], 'http://[HOST]/a');
    });

    test('clips one runaway string instead of the whole buffer', () {
      final short = LogRedactor(ourKeys: const {}, maxStringLength: 10);
      expect(short.scrubString('x' * 50), 'xxxxxxxxxx…[clipped]');
    });
  });

  group('what the application adds', () {
    late LogRedactor configured;

    setUp(() {
      configured = LogRedactor(
        ourKeys: {'id': RegExp(r'^\w+(\.\w+)*$')},
        secretKeyPatterns: [RegExp('serial', caseSensitive: false)],
        valuePatterns: [(RegExp(r'\bbb_[A-Za-z0-9]{8,}'), '[APIKEY]')],
      );
    });

    test('its own secret field names sit on top of the baseline', () {
      final out = configured.scrubFields({'printer_serial': '20P0AA0', 'n': 1});
      expect(out['printer_serial'], '[REDACTED]');
      expect(out['n'], 1);
      // And the baseline is still there underneath.
      expect(configured.scrubFields({'token': 'x'})['token'], '[REDACTED]');
    });

    test('its own value shapes run after the baseline passes', () {
      expect(
        configured.scrubString('key bb_abcdefgh12345 at http://nas.lan'),
        'key [APIKEY] at http://[HOST]',
      );
    });

    test('a field it declared its own skips the scrub, if the shape agrees', () {
      // A server called `queue` would otherwise turn `queue.card` into
      // `[HOST].card` and mangle every control identifier in the log.
      configured.remember('queue', '[HOST]');

      expect(configured.scrubFields({'id': 'queue.card'})['id'], 'queue.card');
      // The shape is the guard, not the name: a value that is not an identifier
      // is not one of ours and goes through the scrub after all.
      expect(
        configured.scrubFields({'id': 'queue item named x'})['id'],
        '[HOST] item named x',
      );
    });
  });

  group('a record the server sent back', () {
    late LogRedactor sampler;

    setUp(() {
      sampler = LogRedactor(
        ourKeys: const {},
        freeTextKeys: const {'name'},
        schemaKeys: const {'dateformat'},
      );
    });

    test('keeps the schema and measures the content', () {
      final out = sampler.scrubSample({
        'id': 7,
        'status': 'printing',
        'ratio': '0.35',
        'created_at': '2026-08-09T12:00:00Z',
        'title': 'Prezent dla Ani',
        'ok': 'true',
      })! as Map;

      // Field names are the API's schema, not the user's data, so they all stay.
      expect(out.keys, containsAll(['id', 'status', 'title']));
      // Technical shapes survive: this is what a wire-format report is read for.
      expect(out['id'], 7);
      expect(out['status'], 'printing');
      expect(out['ratio'], '0.35');
      expect(out['created_at'], '2026-08-09T12:00:00Z');
      expect(out['ok'], 'true');
      // Anything else is the user's, and only its length leaves the phone.
      expect(out['title'], '<str:15>');
    });

    test('an unmodelled free-text field is caught by shape, not by name', () {
      // The whole reason the rule is inverted: a denylist cannot name a field a
      // later server version invents, and this is what it would have missed.
      final out = sampler.scrubSample({
        'some_field_nobody_listed': 'Drukarka w sypialni Kasi',
      })! as Map;

      expect(out['some_field_nobody_listed'], '<str:24>');
    });

    test('a one-word name is measured because the app said the field is free',
        () {
      // `Kuchnia` is the shape of an enum value, so shape alone would keep it.
      expect(sampler.scrubSample('Kuchnia', key: 'name'), '<str:7>');
      // And the same word under a field nobody declared is treated as a token.
      expect(sampler.scrubSample('Kuchnia', key: 'state'), 'Kuchnia');
    });

    test('a schema field keeps its exact formatting', () {
      // `MM/dd/yyyy` is not a date, not a number and not a word, so the shape
      // rule would measure away the one thing the report was about.
      expect(sampler.scrubSample('MM/dd/yyyy', key: 'dateFormat'), 'MM/dd/yyyy');
    });

    test('a secret stays redacted rather than merely measured', () {
      final out = sampler.scrubSample({'api_key': 'bb_abcdefgh'})! as Map;
      expect(out['api_key'], '[REDACTED]');
    });

    test('only the head of a nested list, with the key travelling along', () {
      final out = sampler.scrubSample({
        'name': ['Ania', 'Basia', 'Celina', 'Dorota'],
      })! as Map;

      // Three entries: a fourth says nothing the first did not, and the field is
      // the user's whether it holds one of their words or ten.
      expect(out['name'], ['<str:4>', '<str:5>', '<str:6>']);
    });
  });
}
