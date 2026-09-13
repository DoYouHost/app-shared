/// The screens of a bug report.
///
/// The guided flow — pick a kind, record, review, send or save — the recording
/// bar that follows the user around the app while they reproduce the problem,
/// and the controller both of them render.
///
/// What it takes from `app_diagnostics` and `app_report_client` it takes as
/// instances, not as configuration: the application builds its one recorder
/// and its one sender and hands them over in [ReportBindings], together with
/// the few things only it can know — its root navigator, where "home" is, and
/// what its consent cards promise.
///
/// The application wires three things:
///
/// * `reportBindingsProvider` overridden in its root `ProviderScope`;
/// * `ReportLocalizations.delegate` in `MaterialApp.localizationsDelegates`;
/// * `RecordingBannerScaffold` in `MaterialApp.builder`, and `BugReportScreen`
///   routed at [bugReportRoute].
library;

export 'l10n/report_localizations.dart';
export 'src/bug_report_controller.dart';
export 'src/bug_report_screen.dart';
export 'src/log_export.dart';
export 'src/log_preview.dart';
export 'src/recording_banner.dart' show RecordingBannerScaffold, formatElapsed;
export 'src/report_bindings.dart';
