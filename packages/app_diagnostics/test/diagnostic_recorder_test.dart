import 'dart:convert';
import 'dart:io';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FakeSessionStore sessions;
  late DiagnosticRecorder recorder;

  const facts = SessionFacts(
    app: '0.11.2+1102',
    os: 'Android 15',
    locale: 'pl-PL',
    server: '1.2.5.1',
    secrets: {'sk-live-abcdef': '[APIKEY]', 'bambuddy.local': '[HOST]'},
    extra: {'flavor': 'mobile', 'auth': 'apiKey'},
  );

  setUp(() async {
    sessions = FakeSessionStore();
    dir = Directory.systemTemp.createTempSync('bambuddy_diag');
    recorder = DiagnosticRecorder(
      sessions: sessions,
      redactor: testRedactor,
      loadFacts: () async => facts,
      resolveDirectory: () async => dir,
    );
  });

  tearDown(() async {
    await recorder.discard();
    dir.deleteSync(recursive: true);
  });

  List<Map<String, dynamic>> parse(String jsonl) => [
    for (final line in const LineSplitter().convert(jsonl))
      jsonDecode(line) as Map<String, dynamic>,
  ];

  test('a session opens with a header built from the facts', () async {
    await recorder.start();
    final header = parse(await recorder.stop()).first;

    expect(header['app'], '0.11.2+1102');
    expect(header['flavor'], 'mobile');
    expect(header['os'], 'Android 15');
    expect(header['locale'], 'pl-PL');
    // The server build is the first question any report raises; it belongs in
    // the header, not somewhere down the records.
    expect(header['server'], '1.2.5.1');
    // Carried through `SessionFacts.extra`, and still a flat top-level key on
    // the line — which is what lets an app move a field there without moving
    // anything on the wire.
    expect(header['flavor'], 'mobile');
    expect(header['auth'], 'apiKey');
    expect((header['session'] as String), hasLength(32));
  });

  group('the application\'s own probes', () {
    test(
      'are told a session opened, and told before any tap can land',
      () async {
        // A probe that reports only *changes* carries state from the last
        // session: without this its first event of the new one reads as
        // "unchanged" and never reaches the log at all.
        final listener = RecordingListener();
        final withProbe = DiagnosticRecorder(
          sessions: sessions,
          redactor: testRedactor,
          loadFacts: () async => facts,
          resolveDirectory: () async => dir,
          listeners: [listener],
        );
        addTearDown(withProbe.discard);

        await withProbe.start();

        expect(listener.calls, ['start']);
      },
    );

    test('are told to flush before the session stops taking records', () async {
      // A counter still being aggregated has to get its last record *into*
      // this session; flushed after the store closed, it is thrown away.
      final listener = RecordingListener();
      final withProbe = DiagnosticRecorder(
        sessions: sessions,
        redactor: testRedactor,
        loadFacts: () async => facts,
        resolveDirectory: () async => dir,
        listeners: [listener],
      );

      await withProbe.start();
      await withProbe.stop();

      expect(listener.calls, ['start', 'flush']);
    });
  });

  test('brackets the session with start and stop markers', () async {
    await recorder.start();
    final records = parse(await recorder.stop()).skip(1).toList();

    expect(records.first['evt'], 'recording_started');
    expect(records.last['evt'], 'recording_stopped');
  });

  test('exposes the buffer only while recording', () async {
    expect(DiagnosticRecorder.active, isNull);
    expect(DiagnosticRecorder.isRecording, isFalse);

    await recorder.start();
    expect(DiagnosticRecorder.active, isNotNull);
    expect(DiagnosticRecorder.isRecording, isTrue);

    await recorder.stop();
    expect(DiagnosticRecorder.active, isNull);
  });

  test('instrumentation writes through the static handle', () async {
    await recorder.start();
    DiagnosticRecorder.active?.add(
      LogSource.http,
      'response',
      fields: const {'method': 'GET', 'path': '/printers', 'status': 502},
    );

    final records = parse(await recorder.stop());
    expect(
      records.any((r) => r['evt'] == 'response' && r['status'] == 502),
      isTrue,
    );
  });

  test('the session redactor is seeded from the facts', () async {
    await recorder.start();
    DiagnosticRecorder.active?.add(
      LogSource.err,
      'uncaught',
      fields: const {'msg': 'rejected sk-live-abcdef by bambuddy.local'},
    );

    final log = await recorder.stop();
    expect(log, contains('rejected [APIKEY] by [HOST]'));
    expect(log, isNot(contains('sk-live-abcdef')));
  });

  test('publishes the session id for the background isolate', () async {
    await recorder.start();
    final session = sessions.loadSession();

    expect(session, isNotNull);
    expect(session, hasLength(32));

    await recorder.stop();
    expect(sessions.loadSession(), isNull);
  });

  test(
    'mirrors the stream to disk so a crash mid-recording survives',
    () async {
      await recorder.start();
      DiagnosticRecorder.active?.add(LogSource.app, 'something_happened');
      final session = sessions.loadSession()!;
      await recorder.stop();

      final onDisk = await LogFileSink(
        LogFileSink.fileFor(dir, session, LogStream.ui),
      ).read();
      expect(onDisk, contains('something_happened'));
    },
  );

  test('merges the background stream found on disk', () async {
    await recorder.start();
    final session = sessions.loadSession()!;

    // Stands in for the FGS isolate, which writes its own file with its own
    // header while the UI session runs.
    final fgs = LogFileSink(LogFileSink.fileFor(dir, session, LogStream.fgs));
    await fgs.writeHeader(
      LogHeader(
        ts: DateTime.now().toUtc(),
        session: session,
        app: '0.11.2+1102',
        stream: LogStream.fgs,
      ),
    );
    fgs.writeLine('{"t":10,"src":"fgs","evt":"cycle"}');
    await fgs.close();

    final merged = parse(await recorder.stop());
    expect(merged.first['stream'], 'merged');
    expect(merged.any((r) => r['evt'] == 'cycle'), isTrue);
  });

  test('starting twice keeps the first session', () async {
    await recorder.start();
    final first = sessions.loadSession();

    await recorder.start();

    expect(sessions.loadSession(), first);
  });

  test('stop without start yields nothing', () async {
    expect(await recorder.stop(), isEmpty);
  });

  test('discard deletes both stream files and clears the flag', () async {
    await recorder.start();
    final session = sessions.loadSession()!;
    DiagnosticRecorder.active?.add(LogSource.app, 'x');

    await recorder.discard();

    expect(sessions.loadSession(), isNull);
    expect(DiagnosticRecorder.active, isNull);
    expect(
      LogFileSink.fileFor(dir, session, LogStream.ui).existsSync(),
      isFalse,
    );
  });

  test('discarding after the review deletes the files too', () async {
    // The only discard the app actually offers: the button lives on the review
    // screen, which is reached after stopping.
    await recorder.start();
    final session = sessions.loadSession()!;
    DiagnosticRecorder.active?.add(LogSource.app, 'x');
    await recorder.stop();

    await recorder.discard();

    expect(dir.listSync(), isEmpty);
    expect(
      LogFileSink.fileFor(dir, session, LogStream.ui).existsSync(),
      isFalse,
    );
  });

  test('a new recording sweeps what earlier ones left behind', () async {
    await recorder.start();
    final abandoned = sessions.loadSession()!;
    // Stopped and never sent, the way a user who forgot about it leaves it.
    await recorder.stop();
    // As if the app had died mid-recording: the isolate's file has no owner.
    LogFileSink.fileFor(dir, 'deadbeef', LogStream.fgs).writeAsStringSync('{}');
    final unrelated = File('${dir.path}/notes.txt')..writeAsStringSync('keep');

    await recorder.start();
    final current = sessions.loadSession()!;

    final left = dir.listSync().map((e) => e.uri.pathSegments.last).toSet();
    expect(left, {
      LogFileSink.fileFor(dir, current, LogStream.ui).uri.pathSegments.last,
      unrelated.uri.pathSegments.last,
    });
    expect(left.any((name) => name.contains(abandoned)), isFalse);
  });

  test('hands back the session an app died in the middle of', () async {
    await recorder.start();
    final session = sessions.loadSession()!;
    DiagnosticRecorder.active?.add(LogSource.app, 'the_last_thing_it_saw');
    // No stop and no discard: the process is gone, the flag stays in prefs and
    // the file is whatever the mirror had already flushed. Mirror writes are
    // fire-and-forget, so wait for the chain rather than for the clock.
    await recorder.flushMirror();

    final recovered = await recorder.recover(session);

    expect(recovered, contains('the_last_thing_it_saw'));
    expect(parse(recovered).first['session'], session);
  });

  test('merges the background stream into a recovered session', () async {
    await recorder.start();
    final session = sessions.loadSession()!;
    DiagnosticRecorder.active?.add(LogSource.app, 'from_the_ui');
    await recorder.flushMirror();
    final fgs = LogFileSink(LogFileSink.fileFor(dir, session, LogStream.fgs));
    await fgs.writeHeader(
      LogHeader(
        ts: DateTime.now().toUtc(),
        session: session,
        app: '0.11.2+1102',
        stream: LogStream.fgs,
      ),
    );
    fgs.writeLine('{"t":10,"src":"fgs","evt":"cycle"}');
    await fgs.close();

    final recovered = await recorder.recover(session);

    expect(recovered, contains('from_the_ui'));
    expect(recovered, contains('cycle'));
  });

  test('offers nothing when the crash beat the first record', () async {
    // A file holding only its header is not a report; asking the user to decide
    // about it is worse than saying nothing.
    await recorder.start();
    final session = sessions.loadSession()!;
    // Stopped first so the sink is closed and cannot append behind the test.
    await recorder.stop();
    LogFileSink.fileFor(
      dir,
      session,
      LogStream.ui,
    ).writeAsStringSync('{"v":1,"session":"$session"}\n');

    expect(await recorder.recover(session), isEmpty);
  });

  test('a recovered session can still be thrown away', () async {
    await recorder.start();
    final session = sessions.loadSession()!;
    DiagnosticRecorder.active?.add(LogSource.app, 'x');
    await recorder.recover(session);

    // Discarding what is on the review screen, whether it got there by being
    // stopped or by surviving a crash.
    await recorder.discard();

    expect(
      LogFileSink.fileFor(dir, session, LogStream.ui).existsSync(),
      isFalse,
    );
  });

  /// A recorder whose ring fills in a few records — the real one takes four
  /// megabytes to rotate, which through a sink that flushes every line is not a
  /// test.
  DiagnosticRecorder withTinyRing({
    Future<Directory?> Function()? resolveDirectory,
  }) {
    final tiny = DiagnosticRecorder(
      sessions: sessions,
      redactor: testRedactor,
      loadFacts: () async => facts,
      resolveDirectory: resolveDirectory ?? () async => dir,
      ringRecords: 3,
    );
    addTearDown(tiny.discard);
    return tiny;
  }

  test('a session that rotated the ring still goes out whole', () async {
    final tiny = withTinyRing();
    await tiny.start();
    for (var i = 0; i < 8; i++) {
      DiagnosticRecorder.active?.add(LogSource.app, 'step_$i');
    }

    final log = await tiny.stop();

    // The ring held three of these by the end; the file held all of them, and
    // the file is what the report is made of.
    for (var i = 0; i < 8; i++) {
      expect(log, contains('step_$i'));
    }
    expect(
      log,
      contains('recording_started'),
      reason: 'the start of the session is what eviction used to eat',
    );
    expect(
      log,
      isNot(contains('truncated')),
      reason: 'nothing is missing, so nothing should claim a gap',
    );
  });

  test('a memory-only session still reports what the ring dropped', () async {
    final tiny = withTinyRing(resolveDirectory: () async => null);
    await tiny.start();
    for (var i = 0; i < 8; i++) {
      DiagnosticRecorder.active?.add(LogSource.app, 'step_$i');
    }

    final log = await tiny.stop();

    // No file to fall back on: the ring is the session, and it says so.
    expect(log, contains('truncated'));
    expect(log, isNot(contains('step_0')));
    expect(log, contains('step_7'));
  });

  test(
    'the session read back from disk is in the order things happened',
    () async {
      await recorder.start();
      // A tap is stamped with the moment the finger went down, so it can be
      // written after an event that happened later — which is the whole reason
      // the ring's export sorted, and the file does not.
      DiagnosticRecorder.active?.add(LogSource.ui, 'late_write', at: 900);
      DiagnosticRecorder.active?.add(LogSource.ui, 'early_touch', at: 100);

      final records = parse(await recorder.stop()).skip(1).toList();
      final offsets = [for (final r in records) r['t'] as int];

      expect(offsets, orderedEquals([...offsets]..sort()));
      expect(
        records.indexWhere((r) => r['evt'] == 'early_touch'),
        lessThan(records.indexWhere((r) => r['evt'] == 'late_write')),
      );
    },
  );

  test('an unwritable directory degrades to a memory-only session', () async {
    final memoryOnly = DiagnosticRecorder(
      sessions: sessions,
      redactor: testRedactor,
      loadFacts: () async => facts,
      resolveDirectory: () async => throw const FileSystemException('nope'),
    );

    await memoryOnly.start();
    DiagnosticRecorder.active?.add(LogSource.app, 'still_recorded');
    final log = await memoryOnly.stop();

    expect(log, contains('still_recorded'));
    expect(dir.listSync(), isEmpty);
  });

  test(
    'an uncaught exception lands in the session, and only while it runs',
    () async {
      final beforeAnyRecording = FlutterError.onError;
      void crash(String message) => FlutterError.reportError(
        FlutterErrorDetails(exception: StateError(message)),
      );

      crash('before');
      await recorder.start();
      crash('during');
      final log = await recorder.stop();
      crash('after');

      expect(log, contains('"evt":"uncaught"'));
      expect(log, contains('Bad state: during'));
      expect(log, isNot(contains('before')));
      // The session put Flutter's own handling back exactly as it found it.
      expect(FlutterError.onError, same(beforeAnyRecording));
    },
  );
}
