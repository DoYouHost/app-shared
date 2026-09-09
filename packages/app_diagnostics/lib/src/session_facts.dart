import 'log_event.dart';

/// Everything the recorder needs to describe a session, plus the exact secrets
/// it must never let through. Gathered once when recording starts — reading
/// package info and secure storage is async, and neither changes mid-session.
///
/// The application gathers these; this package only says what shape they take.
/// Where they come from — a package-info channel, a stored profile, a keystore
/// — is the application's business and differs between them, which is why
/// nothing here reads a device.
class SessionFacts {
  const SessionFacts({
    required this.app,
    this.os,
    this.locale,
    this.server,
    this.serverUrl,
    this.secrets = const {},
    this.extra = const {},
  });

  final String app;
  final String? os;
  final String? locale;

  /// Server version, as the server itself reports it. Empty when it could not
  /// be reached or answered something unparseable, which is itself worth seeing
  /// in a report.
  final String? server;

  final ServerFingerprint? serverUrl;

  /// Exact value → redaction label, handed to the session's redactor.
  final Map<String, String> secrets;

  /// The application's own header fields — a build flavor, a device model, an
  /// auth mode, a demo flag. Carried onto the header line as plain top-level
  /// keys; see [LogHeader.extra].
  final Map<String, Object?> extra;

  LogHeader toHeader({
    required DateTime ts,
    required String session,
    LogStream stream = LogStream.ui,
  }) => LogHeader(
    ts: ts,
    session: session,
    app: app,
    stream: stream,
    os: os,
    locale: locale,
    server: server,
    serverUrl: serverUrl,
    extra: extra,
  );
}
