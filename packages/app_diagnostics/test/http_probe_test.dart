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

    test(
      'an answer JSON cannot carry costs the sample, not the call',
      () async {
        // What a custom transformer hands back is not necessarily JSON-shaped.
        final dio = Dio(BaseOptions(baseUrl: 'http://server.lan:8080'))
          ..httpClientAdapter = _CannedAdapter({'state': 'printing'})
          ..interceptors.addAll([
            InterceptorsWrapper(
              onResponse: (response, handler) {
                response.data = {'at': DateTime.utc(2026)};
                handler.next(response);
              },
            ),
            HttpProbe(
              config: HttpProbeConfig(sampledPaths: RegExp(r'/api/v1/queue')),
            ),
          ]);

        await expectLater(dio.get<dynamic>('/api/v1/queue'), completes);

        expect((await responseRecord())['first'], isA<String>());
      },
    );

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

  group('the body a write sends', () {
    Future<Map<String, dynamic>> requestRecord() async =>
        (await records()).firstWhere((r) => r['evt'] == 'request');

    test('is left out unless the app opts in', () async {
      final dio = dioWith(const HttpProbeConfig());

      await dio.post<dynamic>('/api/records', data: {'odometer': '1000'});

      expect((await requestRecord()).containsKey('body'), isFalse);
    });

    test('keeps the wire values and measures out the user text', () async {
      final dio = dioWith(const HttpProbeConfig(sampleRequests: true));

      await dio.post<dynamic>(
        '/api/records',
        data: {
          'date': '01/15/2024',
          'odometer': '148230',
          'note': 'bought from a friend',
        },
      );

      expect((await requestRecord())['body'], {
        'date': '01/15/2024',
        'odometer': '148230',
        'note': '<str:20>',
      });
    });

    test('past the ceiling is clipped rather than dropped', () async {
      final dio = dioWith(
        const HttpProbeConfig(
          sampleRequests: true,
          maxSampleChars: 60,
          maxClippedChars: 20,
        ),
      );

      await dio.post<dynamic>(
        '/api/records',
        data: {for (var i = 0; i < 40; i++) 'k$i': 'True'},
      );

      final body = (await requestRecord())['body'] as String;
      expect(body, hasLength(21));
      expect(body, endsWith('…'));
    });

    test('of an upload is described, never quoted', () async {
      final dio = dioWith(const HttpProbeConfig(sampleRequests: true));
      final form = FormData()
        ..fields.add(const MapEntry('kind', 'receipt'))
        ..files.add(
          MapEntry(
            'documents',
            MultipartFile.fromBytes([1, 2, 3, 4], filename: 'Anna receipt.PDF'),
          ),
        );

      await dio.post<dynamic>('/api/documents/upload', data: form);

      final body = (await requestRecord())['body'] as Map<String, dynamic>;
      expect(body, {
        'fields': ['kind'],
        'files': 1,
        'bytes': 4,
        'exts': ['pdf'],
      });
      expect(jsonEncode(body), isNot(contains('Anna')));
    });

    test('never reaches the response record', () async {
      final dio = dioWith(const HttpProbeConfig(sampleRequests: true));

      await dio.post<dynamic>('/api/records', data: {'odometer': '1000'});

      expect((await responseRecord()).containsKey('body'), isFalse);
    });

    test('an unencodable body costs the sample, not the call', () async {
      // Dio sends a stream as it is; the record cannot quote one, and a probe
      // that handed it on to the store would fail the request on the encode.
      final dio = dioWith(const HttpProbeConfig(sampleRequests: true));

      await expectLater(
        dio.post<dynamic>(
          '/api/records',
          data: Stream.value([1, 2, 3]),
          options: Options(headers: {Headers.contentLengthHeader: 3}),
        ),
        completes,
      );

      expect((await requestRecord())['body'], isA<String>());
    });

    test('is never taken on a route where credentials travel', () async {
      final dio = dioWith(
        HttpProbeConfig(sampleRequests: true, neverSampled: RegExp('login')),
      );

      await dio.post<dynamic>('/api/login', data: {'pin': '4711'});

      expect((await requestRecord()).containsKey('body'), isFalse);
    });

    test('of raw bytes is a size, not the first few bytes', () async {
      final dio = dioWith(const HttpProbeConfig(sampleRequests: true));

      await dio.post<dynamic>(
        '/api/records',
        data: Uint8List.fromList(List.filled(512, 7)),
      );

      expect((await requestRecord())['body'], '<512 bytes>');
    });

    test('sent as a JSON string is sampled like the map it encodes', () async {
      final dio = dioWith(const HttpProbeConfig(sampleRequests: true));

      await dio.post<dynamic>(
        '/api/records',
        data: jsonEncode({'odometer': '1000', 'note': 'bought from a friend'}),
      );

      expect((await requestRecord())['body'], {
        'odometer': '1000',
        'note': '<str:20>',
      });
    });
  });
}
