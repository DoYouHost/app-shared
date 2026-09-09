import 'dart:convert';
import 'dart:typed_data';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Answers every request from a canned body, so the probe is the only thing
/// under test. A real adapter would drag in a socket and a timeout.
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.body, {this.status = 200});

  final Object? body;
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiagnosticRecorder recorder;

  setUp(() async {
    HttpProbe.openSession();
    recorder = DiagnosticRecorder(
      sessions: FakeSessionStore(),
      redactor: testRedactor,
      loadFacts: () async => const SessionFacts(app: '1.0.0+1'),
      // Memory only: this is about what the probe writes, not about files.
      resolveDirectory: () async => null,
    );
    await recorder.start();
  });

  tearDown(() => recorder.discard());

  Dio dioWith(HttpProbeConfig config, {Object? body, int status = 200}) =>
      Dio(BaseOptions(baseUrl: 'http://server.lan:8080'))
        ..httpClientAdapter = _CannedAdapter(body, status: status)
        ..interceptors.add(HttpProbe(config: config));

  Future<List<Map<String, dynamic>>> records() async => [
    for (final line
        in const LineSplitter().convert(await recorder.stop()).skip(1))
      jsonDecode(line) as Map<String, dynamic>,
  ];

  Future<Map<String, dynamic>> responseRecord() async =>
      (await records()).firstWhere((r) => r['evt'] == 'response');

  group('what gets sampled', () {
    test('nothing at all, without a configured route list', () async {
      // The default has to be silence. A package that guessed which of an
      // application's routes were safe to quote would be guessing about that
      // app's payloads, which is the one thing it cannot see.
      final dio = dioWith(const HttpProbeConfig(), body: {'name': 'Ala'});

      await dio.get<dynamic>('/api/v1/queue');

      expect((await responseRecord()).containsKey('first'), isFalse);
    });

    test('a listed route contributes its first record', () async {
      final dio = dioWith(
        HttpProbeConfig(sampledPaths: RegExp(r'/api/v1/queue')),
        body: [
          {'state': 'printing'},
        ],
      );

      await dio.get<dynamic>('/api/v1/queue');

      expect((await responseRecord())['first'], {'state': 'printing'});
    });

    test('an unlisted route contributes nothing', () async {
      final dio = dioWith(
        HttpProbeConfig(sampledPaths: RegExp(r'/api/v1/queue')),
        body: {'state': 'printing'},
      );

      await dio.get<dynamic>('/api/v1/printers');

      expect((await responseRecord()).containsKey('first'), isFalse);
    });

    test('neverSampled beats a route the list would have matched', () async {
      // The ordering is the whole guarantee: credentials live behind routes
      // that otherwise look exactly like content, so this may not be a question
      // of which pattern is written first.
      final dio = dioWith(
        HttpProbeConfig(
          sampledPaths: RegExp(r'/api/v1/'),
          neverSampled: RegExp(r'token'),
        ),
        body: {'access_token': 'secret'},
      );

      await dio.get<dynamic>('/api/v1/token');

      expect((await responseRecord()).containsKey('first'), isFalse);
    });

    test('a sample past the ceiling is clipped rather than dropped', () async {
      // The body is many short recognisable values on purpose. One long
      // unrecognised string never reaches this ceiling at all — `scrubSample`
      // has already measured it away to `<str:500>` — so a record only grows
      // past the limit by being *wide*, which is what a real listing does.
      final dio = dioWith(
        HttpProbeConfig(
          sampledPaths: RegExp(r'/api/v1/queue'),
          maxSampleChars: 60,
          maxClippedChars: 20,
        ),
        body: {for (var i = 0; i < 40; i++) 'k$i': 'printing'},
      );

      await dio.get<dynamic>('/api/v1/queue');

      final first = (await responseRecord())['first'] as String;
      expect(first, hasLength(21));
      expect(first, endsWith('…'));
    });

    test('a sample under the ceiling stays a map, not a string', () async {
      // The readable form is the point of a sample: a reader should be able to
      // see the shape of what the server sent, not an escaped quotation of it.
      final dio = dioWith(
        HttpProbeConfig(sampledPaths: RegExp(r'/api/v1/queue')),
        body: {'state': 'printing'},
      );

      await dio.get<dynamic>('/api/v1/queue');

      expect((await responseRecord())['first'], isA<Map<String, dynamic>>());
    });

    test('the redactor can be turned off for a route that needs it', () async {
      // On by default, and an application has to be able to say why a payload
      // holds nothing of anybody's before it opts out.
      final dio = dioWith(
        HttpProbeConfig(
          sampledPaths: RegExp(r'/api/v1/queue'),
          redactSamples: false,
        ),
        body: {'note': 'x' * 20},
      );

      await dio.get<dynamic>('/api/v1/queue');

      expect((await responseRecord())['first'], {'note': 'x' * 20});
    });
  });

  group('the path a record carries', () {
    test('is the request path when the app supplies no rule', () async {
      final dio = dioWith(const HttpProbeConfig());

      await dio.get<dynamic>('/api/v1/printers/7');

      expect((await responseRecord())['path'], '/api/v1/printers/7');
    });

    test('goes through the app rule when it supplies one', () async {
      // A path can carry the user's own text in a segment, and no redactor
      // catches that — it is a path, not a field.
      final dio = dioWith(
        HttpProbeConfig(pathOf: (path) => path.replaceAll('faktura.pdf', '*')),
      );

      await dio.get<dynamic>('/api/v1/files/faktura.pdf');

      expect((await responseRecord())['path'], '/api/v1/files/*');
    });

    test('never carries the query string, where the tokens are', () async {
      final dio = dioWith(const HttpProbeConfig());

      await dio.get<dynamic>(
        '/api/v1/printers',
        queryParameters: {'token': 'secret'},
      );

      expect((await responseRecord())['path'], '/api/v1/printers');
    });
  });

  group('per-request fields the app adds', () {
    test('reach the response record', () async {
      final dio = dioWith(
        HttpProbeConfig(
          fieldsOf: (options) => {'vid': options.uri.queryParameters['vid']},
        ),
      );

      await dio.get<dynamic>('/api/v1/records', queryParameters: {'vid': '4'});

      expect((await responseRecord())['vid'], '4');
    });

    test('reach the request record of a write', () async {
      final dio = dioWith(HttpProbeConfig(fieldsOf: (_) => {'vid': '4'}));

      await dio.post<dynamic>('/api/v1/records');

      final request = (await records()).firstWhere(
        (r) => r['evt'] == 'request',
      );
      expect(request['vid'], '4');
    });

    test('an extractor that throws costs the fields, not the call', () async {
      // This runs on every request the app makes. An extractor tripping over
      // one odd URL must not be why a call fails.
      final dio = dioWith(
        HttpProbeConfig(fieldsOf: (_) => throw StateError('bad url')),
      );

      await expectLater(dio.get<dynamic>('/api/v1/printers'), completes);

      expect((await responseRecord())['status'], 200);
    });
  });
}
