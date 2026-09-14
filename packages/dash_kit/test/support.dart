import 'dart:convert';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_client/app_report_client.dart';
import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _brand = DashBrand(
  dark: DashAccent(fill: Color(0xFF5FE08A), ink: Color(0xFF5FE08A)),
  light: DashAccent(fill: Color(0xFF34C46E), ink: Color(0xFF18733D)),
  onAccent: Color(0xFF0A0C08),
);

ThemeData get testTheme => buildDashThemeData(Brightness.light, brand: _brand);

/// [child] as the home of an app themed the way both applications are, so a
/// measurement that depends on button padding measures the real one.
Future<void> pumpPhone(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(theme: testTheme, home: child));

class _MemorySessions implements DiagnosticsSessionStore {
  String? _session;

  @override
  String? loadSession() => _session;

  @override
  Future<void> saveSession(String? session) async => _session = session;
}

/// A recording kept in memory, read back as the records after the header.
class Recording {
  final recorder = DiagnosticRecorder(
    sessions: _MemorySessions(),
    redactor: () => LogRedactor(
      ourKeys: {
        'id': RegExp(r'^\w+(\.\w+)*$'),
        'surface': RegExp(r'^\w+(\.\w+)*$'),
      },
    ),
    sessionDuration: const Duration(minutes: 30),
    sessionBytes: 1024 * 1024,
    loadFacts: () async => const SessionFacts(app: '0.0.0+0'),
    resolveDirectory: () async => null,
  );

  Future<void> start() async {
    await recorder.start();
    addTearDown(() async {
      if (DiagnosticRecorder.isRecording) await recorder.stop();
    });
  }

  Future<List<Map<String, Object?>>> stop() async => [
    for (final line
        in const LineSplitter().convert(await recorder.stop()).skip(1))
      jsonDecode(line) as Map<String, Object?>,
  ];
}

/// The widget a control is tagged with, by the id the log records.
Finder byLogId(String id) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.identifier == id,
);
