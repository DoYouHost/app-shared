/// The half of a bug report that produces it.
///
/// One recording session: the header describing it, the ring buffer and the
/// file each isolate mirrors into, the merge that puts those files back on one
/// timeline, the summary a user reviews before sending, and the probes that
/// watch taps, routes, requests, errors and lifecycle.
///
/// What happens to a finished report — the ticket transport, the outbox, the
/// redaction vocabulary — is `app_report_client`, which this package depends on
/// for the redactor alone.
///
/// Six things bind it to an application, and each is a parameter rather than a
/// default, because a wrong guess about any of them either loses a report or
/// puts something in one that must not be there:
///
/// * `DiagnosticRecorder.sessions` — where the running session's id is kept;
/// * `DiagnosticRecorder.redactor` — what must never reach a log, which is a
///   vocabulary of that app's nouns;
/// * `DiagnosticRecorder.sessionDuration` / `sessionBytes` — how long a
///   recording may run and how large it may get;
/// * `DiagnosticRecorder.listeners` — the app's own probes, told when a session
///   opens and closes;
/// * `HttpProbe.config` — which routes are sampled, which are never sampled;
/// * `InteractionProbe.decompose` — how to read an app's own identifier
///   grammar.
///
/// `LogSource` and `LogStream` are the union of what the applications on this
/// package emit; adding a value is a change here, on purpose.
library;

export 'src/diagnostic_recorder.dart';
export 'src/error_probe.dart';
export 'src/http_probe.dart';
export 'src/interaction_probe.dart';
export 'src/lifecycle_probe.dart';
export 'src/log_event.dart';
export 'src/log_file_sink.dart';
export 'src/log_merge.dart';
export 'src/log_path.dart';
export 'src/log_store.dart';
export 'src/log_summary.dart';
export 'src/log_tag.dart';
export 'src/navigation_probe.dart';
export 'src/session_facts.dart';
export 'src/session_ports.dart';
