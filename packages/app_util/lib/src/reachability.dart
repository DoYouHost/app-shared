import 'dio_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Whether the server is answering at all, as one answer for the whole app.
///
/// Without it every screen finds this out for itself: a cold start with the
/// server out of reach shows a spinner on the first screen until its own
/// request times out, then the same spinner and the same wait on the next one —
/// one connect timeout per screen the user happens to open, each re-learning
/// what the first already knew.
///
/// Fed by [ReachabilityProbe] on the shared Dio, so *any* request answers for
/// all of them: a reply of any status (a 404 and a 403 included) means the
/// server is there, and only a transport failure ([DioFailure.unreachable])
/// means it is not. `null` is "nothing has been tried yet".
///
/// Deliberately not a connectivity check: what matters is this server, not
/// whether the phone has a network — a LAN server is out of reach from mobile
/// data with every radio reporting itself connected.
class ServerReachability {
  /// One per isolate: the UI isolate and a background one each have their own
  /// Dio and their own answer.
  static final instance = ServerReachability();

  /// A [ValueListenable] rather than a provider: the widget that reads it is
  /// the shared error state, which is pumped without a `ProviderScope` in
  /// plenty of widget tests.
  final ValueNotifier<bool?> reachable = ValueNotifier(null);

  /// The server answered — whatever it said.
  void sawAnswer() => reachable.value = true;

  /// A request came back without the server having said anything.
  ///
  /// Two of the failures say nothing about the server. A download the
  /// user walked away from ([DioFailure.cancelled], a `CancelToken`) and a
  /// failure Dio could not name say nothing, and recording them as "answering" would put
  /// the next screen back on its own timeout.
  void sawFailure(DioException error) {
    switch (classifyDioException(error)) {
      case DioFailure.unreachable:
        reachable.value = false;
      case DioFailure.cancelled || DioFailure.unknown:
        break;
      case DioFailure.unauthorized ||
          DioFailure.forbidden ||
          DioFailure.tooManyRequests ||
          DioFailure.badResponse ||
          DioFailure.badCertificate:
        // A certificate rejected is still something answering at that address.
        reachable.value = true;
    }
  }

  /// A new server (or none): what the old one answered says nothing about it.
  void forget() => reachable.value = null;
}

/// Records on [reachability] what every request through this Dio found.
class ReachabilityProbe extends Interceptor {
  ReachabilityProbe(this.reachability);

  final ServerReachability reachability;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    reachability.sawAnswer();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    reachability.sawFailure(err);
    handler.next(err);
  }
}
