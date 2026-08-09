/// Client half of the app report relay.
///
/// Everything here is about getting one report from "the user tapped send" to
/// "here is the issue URL" without losing it, and about what must never be in it
/// in the first place. What the report is *of* — how a session is recorded, what
/// a log record looks like, which facts describe the device — stays in the
/// application: those differ per app, and this package deliberately does not
/// know them.
///
/// Two values bind it to an application and both are required rather than
/// defaulted, because a wrong default here files a user's report into somebody
/// else's repository or under a schema the relay refuses:
///
/// * `RelayClient.baseUrl` — the relay path prefix naming the application;
/// * `ReportSender._formatVersion` — the log schema this build writes.
library;

export 'src/log_redactor.dart';
export 'src/relay_client.dart';
export 'src/relay_identity.dart';
export 'src/relay_pow.dart';
export 'src/report_envelope.dart';
export 'src/report_outbox.dart';
export 'src/report_sender.dart';
