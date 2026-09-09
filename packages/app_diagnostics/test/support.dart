import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_client/app_report_client.dart';

/// The session id in memory, which is all the recorder asks of an application.
class FakeSessionStore implements DiagnosticsSessionStore {
  String? _session;

  @override
  String? loadSession() => _session;

  @override
  Future<void> saveSession(String? session) async => _session = session;
}

/// A redactor with an application's shape but none of its vocabulary — enough
/// for the tests here, which are about the recorder and not about what any one
/// app calls its nouns.
LogRedactor testRedactor() =>
    LogRedactor(ourKeys: {'id': RegExp(r'^\w+(\.\w+)*$')});

/// Stands in for an application's session ceiling. The package has no opinion
/// about the real one, so the tests state their own rather than importing a
/// number that would look like a recommendation.
const testSessionLimit = Duration(minutes: 30);

/// Records the two moments a [DiagnosticSessionListener] is told about, so a
/// test can assert the recorder told it.
class RecordingListener implements DiagnosticSessionListener {
  final List<String> calls = [];

  @override
  void onSessionStart() => calls.add('start');

  @override
  void onSessionFlush() => calls.add('flush');
}
