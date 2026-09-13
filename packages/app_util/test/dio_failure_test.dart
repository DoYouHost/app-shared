import 'package:app_util/app_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _status(int status) {
  final options = RequestOptions(path: '/api/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

DioException _ofType(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/api/x'),
  type: type,
);

void main() {
  group('by status', () {
    test('401, 403 and 429 are each their own', () {
      // 401 and 403 decide whether a session ends; 429 must not read as a
      // wrong password when a server rate-limits logins before checking one.
      expect(classifyDioException(_status(401)), DioFailure.unauthorized);
      expect(classifyDioException(_status(403)), DioFailure.forbidden);
      expect(classifyDioException(_status(429)), DioFailure.tooManyRequests);
    });

    test('every other status is a bad response', () {
      for (final status in [400, 404, 409, 422, 500, 502, 503, 504]) {
        expect(
          classifyDioException(_status(status)),
          DioFailure.badResponse,
          reason: 'status $status',
        );
      }
    });

    test('a bad response with no response at all is still one', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/api/x'),
        type: DioExceptionType.badResponse,
      );
      expect(classifyDioException(e), DioFailure.badResponse);
    });
  });

  group('by transport failure', () {
    test('timeouts and connection loss are unreachable', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          classifyDioException(_ofType(type)),
          DioFailure.unreachable,
          reason: '$type',
        );
      }
    });

    test('a rejected certificate is not "unreachable"', () {
      expect(
        classifyDioException(_ofType(DioExceptionType.badCertificate)),
        DioFailure.badCertificate,
      );
    });

    test('cancel and unknown are a connection error', () {
      for (final type in [DioExceptionType.cancel, DioExceptionType.unknown]) {
        expect(
          classifyDioException(_ofType(type)),
          DioFailure.connectionError,
          reason: '$type',
        );
      }
    });
  });
}
