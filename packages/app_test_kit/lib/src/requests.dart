import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// Every request that really left the app, oldest first — what to assert on
/// instead of a mock handler, which runs once at declaration.
class RequestLog {
  final List<RequestOptions> requests = [];

  /// The status of each answer in the order they came back; `null` where the
  /// failure carried no response (an unmatched route). Lines up with [calls] only
  /// when the requests were awaited one at a time.
  final List<int?> statuses = [];

  /// `METHOD /path`. Assert the whole list, not a `contains`.
  List<String> get calls => [for (final r in requests) '${r.method} ${r.path}'];

  /// The most recent request — its `data` is the body a write test asserts on,
  /// its `queryParameters` the query a read test does.
  RequestOptions get last => requests.last;

  /// Just the paths, for a test about which endpoints were reached and in what
  /// order rather than what they carried.
  List<String> get paths => [for (final r in requests) r.path];

  /// Waits until [count] requests have *finished*, for calls started with
  /// `unawaited`. Returns on its deadline rather than throwing.
  Future<void> untilCount(int count, {int turns = 100}) async {
    for (var i = 0; i < turns && statuses.length < count; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

/// Logs every request [dio] makes into the returned [RequestLog]: add it before
/// the act, assert after.
RequestLog captureRequests(Dio dio) {
  final log = RequestLog();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        log.requests.add(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        log.statuses.add(response.statusCode);
        handler.next(response);
      },
      onError: (error, handler) {
        log.statuses.add(error.response?.statusCode);
        handler.next(error);
      },
    ),
  );
  return log;
}

/// The host every test that needs a server talks to.
const fakeServerBaseUrl = 'http://s.local:8000';

/// A Dio pointed at [fakeServerBaseUrl], for a `DioAdapter` to hang off.
Dio testDio() => Dio(BaseOptions(baseUrl: fakeServerBaseUrl));

/// The mock server a test hangs off a Dio, matching the request body exactly
/// rather than by subset.
DioAdapter mockServer(Dio dio) => DioAdapter(
  dio: dio,
  matcher: const FullHttpRequestMatcher(needsExactBody: true),
);

/// A Dio adapter that answers from a script instead of a socket. A step returns a
/// `ResponseBody` or a `DioException`, which is thrown.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(Object Function(RequestOptions options) reply)
    : _steps = [reply];

  /// One step per request, in order. The **last step stands for every request
  /// past the end of the script**, so a retry that fires more often than the
  /// test spelled out is answered rather than crashing on a range error.
  ScriptedAdapter.script(this._steps) : assert(_steps.isNotEmpty);

  final List<Object Function(RequestOptions options)> _steps;

  /// Every request that reached the adapter, oldest first — the retry and
  /// refresh tests are about how many there were and what they carried.
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final step = _steps[(requests.length - 1).clamp(0, _steps.length - 1)];
    final answer = step(options);
    if (answer is DioException) throw answer;
    return answer as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}
