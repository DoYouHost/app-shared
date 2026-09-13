import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_client/app_report_client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the report screen lives. The same in every application, and named
/// here because the recording bar has to know whether it is already showing
/// before it pushes.
const bugReportRoute = '/settings/bug-report';

/// What the consent cards promise about this application's log.
///
/// The application's to say, not this package's: each line is a claim about
/// which probes the app wires up and which of its nouns never reach the log —
/// a background service, a printer's serial number, a vehicle's plate.
typedef ReportConsent = ({
  /// What a recording carries, one scannable line each.
  List<String> recorded,

  /// What it never carries.
  List<String> neverRecorded,

  /// The app's own data a change or feature request leaves out.
  String requestExcludes,
});

/// Everything the report flow needs from the application.
class ReportBindings {
  const ReportBindings({
    required this.recorder,
    required this.sender,
    required this.navigatorKey,
    required this.homeLocation,
    required this.logFilePrefix,
    required this.consent,
    this.maxContentWidth,
  });

  /// The app's one recorder. Its session store, ceilings and facts are what the
  /// flow reads, so none of them is repeated here.
  final DiagnosticRecorder recorder;

  /// The app's one sender, owning the outbox slot.
  final ReportSender sender;

  /// The root navigator: the recording bar lives in `MaterialApp.builder`,
  /// above every route, and pushes the report screen from there.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Where the user goes back to when a recording starts or a report is done,
  /// read at that moment — before setup it is the setup screen, which is the
  /// one worth recording then.
  final String Function() homeLocation;

  /// `bambuddy` → `bambuddy-log-20260728-143005.txt`.
  final String logFilePrefix;

  final ReportConsent Function(BuildContext context) consent;

  /// Caps the screen's width on a tablet; null lets it span the display.
  final double? maxContentWidth;
}

/// Overridden once, in the application's root `ProviderScope`.
final reportBindingsProvider = Provider<ReportBindings>(
  (_) => throw UnimplementedError(
    'reportBindingsProvider has no override: the application has to hand the '
    'report flow its recorder and sender in its root ProviderScope.',
  ),
);
