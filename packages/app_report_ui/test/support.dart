import 'dart:async';
import 'dart:io';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_client/app_report_client.dart';
import 'package:app_report_ui/app_report_ui.dart';
import 'package:dash_ui/dash_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const facts = SessionFacts(
  app: '0.11.2+1102',
  os: 'Android 15',
  locale: 'pl-PL',
);

const sessionDuration = Duration(minutes: 30);

/// Consent lines a test can find, standing in for an application's own.
const consent = (
  recorded: ['Screens you open', 'The background service and its decisions'],
  neverRecorded: ['Your API key or password', 'The text you type'],
  requestExcludes: 'Nothing about your printers',
);

const _brand = DashBrand(
  dark: DashAccent(fill: Color(0xFF5FE08A), ink: Color(0xFF5FE08A)),
  light: DashAccent(fill: Color(0xFF34C46E), ink: Color(0xFF18733D)),
  onAccent: Color(0xFF0A0C08),
);

class MemorySessions implements DiagnosticsSessionStore {
  MemorySessions([this.session]);

  String? session;

  @override
  String? loadSession() => session;

  @override
  Future<void> saveSession(String? session) async => this.session = session;
}

/// One application's worth of report plumbing, real except at its edges: the
/// relay is [FakeRelay], the session id lives in memory, and the outbox and the
/// session files go wherever the test says — nowhere, unless it says.
class Rig {
  Rig({
    FakeRelay? relay,
    Directory? outboxRoot,
    Future<SessionFacts> Function()? loadFacts,
    Directory? logDirectory,
    String? orphanSession,
    bool withProfile = true,
    double? maxContentWidth,
    ReportSender? sender,
    this.saver,
  }) : relay = relay ?? FakeRelay(),
       sessions = MemorySessions(orphanSession) {
    recorder = DiagnosticRecorder(
      sessions: sessions,
      redactor: () => LogRedactor(ourKeys: {'id': RegExp(r'^\w+(\.\w+)*$')}),
      sessionDuration: sessionDuration,
      sessionBytes: 20 * 1024 * 1024,
      loadFacts: loadFacts ?? () async => facts,
      resolveDirectory: () async => logDirectory,
    );
    this.sender =
        sender ??
        ReportSender(
          client: this.relay,
          // With no root the outbox asks path_provider, which a test does not have,
          // and the sender treats that as an empty slot.
          outbox: outboxRoot == null
              ? const ReportOutbox()
              : ReportOutbox(root: outboxRoot),
          installId: () async => 'install',
          demoMode: () => false,
          formatVersion: LogHeader.formatVersion,
        );
    addTearDown(this.sender.dispose);
    bindings = ReportBindings(
      recorder: recorder,
      sender: this.sender,
      navigatorKey: navigatorKey,
      homeLocation: () => withProfile ? '/' : '/setup',
      logFilePrefix: 'app',
      consent: (_) => consent,
      maxContentWidth: maxContentWidth,
    );
  }

  final FakeRelay relay;
  final MemorySessions sessions;
  final LogFileSaver? saver;
  final navigatorKey = GlobalKey<NavigatorState>();
  late final DiagnosticRecorder recorder;
  late final ReportSender sender;
  late final ReportBindings bindings;

  List<Override> get overrides => [
    reportBindingsProvider.overrideWithValue(bindings),
    if (saver case final saver?) logFileSaverProvider.overrideWithValue(saver),
  ];

  ProviderContainer container() {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }
}

ThemeData get testTheme => buildDashThemeData(Brightness.light, brand: _brand);

/// The app the screens run in, in Polish: the strings the tests look for are
/// the package's own translations.
Widget plApp(Widget home, {GlobalKey<NavigatorState>? navigatorKey}) =>
    MaterialApp(
      locale: const Locale('pl'),
      theme: testTheme,
      navigatorKey: navigatorKey,
      localizationsDelegates: ReportLocalizations.localizationsDelegates,
      supportedLocales: ReportLocalizations.supportedLocales,
      home: home,
    );

RelayTicket ticket({Duration wait = Duration.zero}) {
  final now = DateTime.now();
  return RelayTicket(
    ticket: 'signed',
    notBefore: now.add(wait),
    expiresAt: now.add(wait + const Duration(minutes: 30)),
    // Zero bits: the real difficulty is about a second of hashing, which every
    // test using this would otherwise pay.
    challenge: const PowChallenge(seed: 'seed', bits: 0),
  );
}

/// Stands in for the relay. What matters here is not the protocol — the worker's
/// own suite covers that — but *when* the screens talk to it.
class FakeRelay extends RelayClient {
  FakeRelay({this.issued, this.gate})
    : super(Dio(), baseUrl: 'https://relay.example');

  final RelayTicket? issued;

  /// Holds the challenge open, for the one test that needs a second call made
  /// while the first is still in flight. Counted before it is awaited, so what
  /// [challenges] reports is attempts rather than answers.
  final Future<void>? gate;

  int challenges = 0;
  int sends = 0;
  String? lastDescription;
  Map<String, Object>? lastHeader;
  int? lastSchema;
  ReportKind? lastKind;
  String? lastLog;

  @override
  Future<RelayTicket> challenge(String installId) async {
    challenges++;
    await gate;
    final next = issued;
    if (next == null) throw const RelayException(RelayFailure.unreachable);
    return next;
  }

  @override
  Future<String> send({
    required String installId,
    required RelayTicket ticket,
    required ReportKind kind,
    required String description,
    required Map<String, Object> header,
    int? logSchema,
    String? log,
  }) async {
    sends++;
    lastDescription = description;
    lastHeader = header;
    lastSchema = logSchema;
    lastKind = kind;
    lastLog = log;
    return 'https://github.example/issues/7';
  }
}

/// Puts the screens in whatever send state a test needs — including one a
/// previous run left in the outbox — without a relay or a file behind it.
class ScriptedSender implements ReportSender {
  final _states = StreamController<SendState>.broadcast();

  void emit(SendState state) => _states.add(state);

  @override
  Stream<SendState> get states => _states.stream;

  @override
  Future<void> prepare() async {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> cancel() async => emit(const SendState.idle());

  @override
  Future<void> submit({
    required String description,
    required String log,
  }) async {}

  @override
  Future<void> submitRequest({
    required ReportKind kind,
    required String description,
    required ReportEnvelope envelope,
  }) async {}

  @override
  void dispose() => _states.close();
}
