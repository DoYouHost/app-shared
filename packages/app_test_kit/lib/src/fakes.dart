import 'dart:async';

import 'package:app_diagnostics/app_diagnostics.dart';

/// The session id in memory. The real one is `SharedPreferencesSessionStore`;
/// nothing in a test needs it to survive the process.
class MemorySessionStore implements DiagnosticsSessionStore {
  String? _session;

  @override
  String? loadSession() => _session;

  @override
  Future<void> saveSession(String? session) async => _session = session;
}

/// A [Timer] the test fires by hand, keeping the [duration] it was asked for.
class FakeTimer implements Timer {
  FakeTimer(this.duration, this._callback);

  /// What the code under test asked to wait — assert on it rather than on the
  /// wall clock.
  final Duration duration;
  final void Function() _callback;

  bool cancelled = false;

  /// Runs the callback, unless the code cancelled the timer first.
  void fire() {
    if (!cancelled) _callback();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}
