import 'package:app_util/app_util.dart';
import 'package:flutter_test/flutter_test.dart';

const _probe = '/api/v1/auth/status';

void main() {
  group('normalizeBaseUrl', () {
    String http(String raw) => normalizeBaseUrl(raw, defaultScheme: 'http');

    test('a bare host gets the default scheme', () {
      expect(http('printer.example.com'), 'http://printer.example.com');
      expect(http('192.168.1.10:8000'), 'http://192.168.1.10:8000');
      expect(
        normalizeBaseUrl('cars.example.com', defaultScheme: 'https'),
        'https://cars.example.com',
      );
    });

    test('a scheme the user typed is kept', () {
      expect(http('https://host'), 'https://host');
      expect(
        normalizeBaseUrl('http://host', defaultScheme: 'https'),
        'http://host',
      );
    });

    test('trailing slashes and surrounding whitespace go', () {
      expect(http('https://host/'), 'https://host');
      expect(http('https://host///'), 'https://host');
      expect(http('  host  '), 'http://host');
    });

    test('empty stays empty, with no scheme injected', () {
      expect(http(''), '');
      expect(http('   '), '');
    });

    test('the API path is stripped once, after the slashes', () {
      String api(String raw) =>
          normalizeBaseUrl(raw, defaultScheme: 'https', apiPath: '/api');

      expect(api('host/api'), 'https://host');
      expect(api('https://host/api/'), 'https://host');
      expect(api('https://host/proxy/api'), 'https://host/proxy');
      expect(
        http('https://host/api'),
        'https://host/api',
        reason: 'without an apiPath nothing but slashes is stripped',
      );
    });
  });

  group('baseUrlFromReached', () {
    // The WebSocket bug: a bare host is normalized to http://, the https server
    // redirects the probe, and the base has to follow or ws:// goes nowhere.
    test('adopts the redirected https base', () {
      expect(
        baseUrlFromReached(
          Uri.parse('https://host$_probe'),
          requested: 'http://host',
          endpointSuffix: _probe,
        ),
        'https://host',
      );
    });

    test('keeps a non-default port and a reverse-proxy path prefix', () {
      expect(
        baseUrlFromReached(
          Uri.parse('https://host:8443/proxy$_probe'),
          requested: 'http://host:8443/proxy',
          endpointSuffix: _probe,
        ),
        'https://host:8443/proxy',
      );
    });

    test('ignores a query on the reached URI', () {
      expect(
        baseUrlFromReached(
          Uri.parse('https://host$_probe?x=1'),
          requested: 'http://host',
          endpointSuffix: _probe,
        ),
        'https://host',
      );
    });

    test('keeps what was requested when there is nothing to adopt', () {
      expect(
        baseUrlFromReached(
          null,
          requested: 'http://host',
          endpointSuffix: _probe,
        ),
        'http://host',
      );
      expect(
        baseUrlFromReached(
          Uri.parse('https://host/unexpected/path'),
          requested: 'http://host',
          endpointSuffix: _probe,
        ),
        'http://host',
        reason: 'a reached URI of an unexpected shape is not a base',
      );
    });
  });
}
