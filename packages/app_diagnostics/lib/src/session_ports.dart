/// Where the id of a running recording is kept between isolates.
///
/// It is one value, but it is the one that makes a background isolate able to
/// join a session the UI started, so it has to live somewhere both can read —
/// in practice the application's own preferences. The id doubles as the
/// "recording is on" flag: two keys would be two things to keep in sync.
abstract interface class DiagnosticsSessionStore {
  /// Null clears it, which is what stopping or discarding a session does.
  Future<void> saveSession(String? session);

  /// Synchronous on purpose: a background isolate reads this on the path to
  /// deciding whether to record at all, before it has done anything else.
  String? loadSession();
}

/// Something that has to be told when a session opens and when it is being
/// closed, but that this package does not know about.
///
/// The applications each have one: a probe over their WebSocket client, a probe
/// over their image loader. Both sit in the app because both wrap a client the
/// app owns, and both need the same two moments — a session opening (drop the
/// state an earlier one left, or its first event reads as "unchanged"), and a
/// session ending (flush counters that are still being aggregated, or the tail
/// of the story never reaches the file).
abstract interface class DiagnosticSessionListener {
  /// A recording has just started. Clear anything carried over from the last.
  void onSessionStart();

  /// The session is closing. Write out whatever is still being batched.
  ///
  /// Called before the store stops accepting records, and in the background
  /// isolate **after** the isolate's own teardown — a client's `dispose` may
  /// still be writing its last records through the static.
  void onSessionFlush();
}
