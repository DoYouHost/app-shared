import 'package:dio/dio.dart';

/// What went wrong with a request, in the terms both applications build their
/// error codes from.
///
/// This is the part of mapping a [DioException] the two had in common, spelled
/// twice. What each makes of it — which exception class, which code, whether a
/// 403 keeps the server's sentence — stays in the application's own switch
/// over [classifyDioException].
enum DioFailure {
  /// Timed out or never connected: as far as the user can tell, the server is
  /// not there.
  unreachable,

  /// 401.
  unauthorized,

  /// 403 — authenticated, not permitted. Kept apart from [unauthorized] because
  /// one of them ends a session and the other must not.
  forbidden,

  /// 429 — refusing for now, not forever.
  tooManyRequests,

  /// Any other status; the number is on `DioException.response`.
  badResponse,

  /// TLS rejected the certificate. Its own case because self-signed
  /// certificates are common on self-hosted servers, and the remedy is not the
  /// address.
  badCertificate,

  /// Cancelled, or failed in a way Dio could not name.
  connectionError,
}

/// Classifies [e]. Every [DioExceptionType] is named, so a type a later Dio adds
/// fails to compile here instead of landing in a default.
DioFailure classifyDioException(DioException e) => switch (e.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout ||
  DioExceptionType.connectionError => DioFailure.unreachable,
  DioExceptionType.badResponse => switch (e.response?.statusCode) {
    401 => DioFailure.unauthorized,
    403 => DioFailure.forbidden,
    429 => DioFailure.tooManyRequests,
    _ => DioFailure.badResponse,
  },
  DioExceptionType.badCertificate => DioFailure.badCertificate,
  DioExceptionType.cancel ||
  DioExceptionType.unknown => DioFailure.connectionError,
};
