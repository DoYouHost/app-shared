import 'dart:typed_data';

import 'package:app_util/app_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the handler was asked, so a test can check the adapter passed the
/// request on intact.
class _Seen {
  String? method;
  Uri? uri;
  Object? body;
  int calls = 0;
}

Dio _dio(
  _Seen seen,
  DemoResult result, {
  DemoResult Function(FormData form)? uploads,
}) =>
    Dio(BaseOptions(baseUrl: 'https://demo.invalid'))
      ..httpClientAdapter = DemoHttpClientAdapter(
        (method, uri, body) {
          seen
            ..method = method
            ..uri = uri
            ..body = body
            ..calls += 1;
          return result;
        },
        uploads: uploads,
        latency: Duration.zero,
      );

void main() {
  test('routes the request and serves the body as JSON', () async {
    final seen = _Seen();
    final dio = _dio(seen, (status: 200, body: {'ok': true}));

    final res = await dio.post<Map<String, dynamic>>(
      '/api/items',
      queryParameters: {'page': 2},
      data: {'name': 'x'},
    );

    expect(res.data, {'ok': true});
    expect(seen.method, 'POST');
    expect(seen.uri!.path, '/api/items');
    expect(seen.uri!.queryParameters, {'page': '2'});
    expect(seen.body, {'name': 'x'});
  });

  test('a JSON string payload reaches the handler decoded', () async {
    final seen = _Seen();
    final dio = _dio(seen, (status: 204, body: null));

    await dio.put<void>('/api/items/1', data: '{"name":"y"}');

    expect(seen.body, {'name': 'y'});
  });

  test('an error status arrives as one, body and all', () async {
    final dio = _dio(_Seen(), (status: 404, body: {'detail': 'gone'}));

    await expectLater(
      dio.get<void>('/api/items/9'),
      throwsA(
        isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 404)
            .having((e) => e.response?.data, 'data', {'detail': 'gone'}),
      ),
    );
  });

  test('a file is served as its bytes, with its type and length', () async {
    // The length is what a download's progress bar reads its total from.
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final dio = _dio(_Seen(), (
      status: 200,
      body: DemoFile(bytes, 'application/octet-stream'),
    ));
    int? total;

    final res = await dio.get<List<int>>(
      '/api/files/1',
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (_, t) => total = t,
    );

    expect(res.data, bytes);
    expect(
      res.headers.value(Headers.contentTypeHeader),
      'application/octet-stream',
    );
    expect(total, 5);
  });

  group('multipart uploads', () {
    FormData form() => FormData.fromMap({
      'file': MultipartFile.fromBytes([1, 2], filename: 'receipt.pdf'),
    });

    test('go to the upload handler when there is one', () async {
      final seen = _Seen();
      String? name;
      final dio = _dio(
        seen,
        (status: 500, body: null),
        uploads: (form) {
          name = form.files.single.value.filename;
          return (status: 200, body: ['stored']);
        },
      );

      final res = await dio.post<List<dynamic>>('/api/upload', data: form());

      expect(res.data, ['stored']);
      expect(name, 'receipt.pdf');
      expect(seen.calls, 0, reason: 'the JSON handler is not asked');
    });

    test('reach the JSON handler with no body when there is none', () async {
      final seen = _Seen();
      final dio = _dio(seen, (status: 501, body: {'detail': 'not in demo'}));

      await expectLater(
        dio.post<void>('/api/upload', data: form()),
        throwsA(isA<DioException>()),
      );
      expect(seen.calls, 1);
      expect(seen.body, isNull);
    });
  });
}
