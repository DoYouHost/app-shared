import 'package:shared_preferences/shared_preferences.dart';

import 'session_ports.dart';

/// The running session's id, kept where every isolate can read it.
///
/// Preferences rather than memory because the isolates share no Dart state: a
/// recording started in the app reaches a background isolate through this file
/// and nothing else. The id doubles as the flag — a separate bool would be a
/// second thing to keep in sync — and an id left behind at startup is how an
/// app that died mid-recording is noticed.
///
/// [loadSession] is synchronous, as the port requires, so it cannot refresh the
/// snapshot itself: `SharedPreferences` gives every isolate its own copy of the
/// file. An isolate that did not write the id must `reload()` its preferences
/// before building this, or it reads the state it started with.
class SharedPreferencesSessionStore implements DiagnosticsSessionStore {
  const SharedPreferencesSessionStore(this._prefs, {this.key = _defaultKey});

  static const _defaultKey = 'diagnostics_session';

  final SharedPreferences _prefs;

  /// The preferences key. Both applications shipped [_defaultKey] before this
  /// class existed, and it is read natively in one of them, so it is a wire
  /// value rather than an implementation detail.
  final String key;

  @override
  String? loadSession() {
    final session = _prefs.getString(key);
    // An empty string is an id nothing can be recorded under; earlier versions
    // could leave one behind.
    return (session == null || session.isEmpty) ? null : session;
  }

  @override
  Future<void> saveSession(String? session) =>
      session == null ? _prefs.remove(key) : _prefs.setString(key, session);
}
