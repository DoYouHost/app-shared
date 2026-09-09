import 'dart:convert';
import 'dart:math';

/// Subsystem a record came from, not an isolate — which isolate wrote it is the
/// stream's business. Notifications get their own [notif] even where only a
/// background service produces them: "the app buried me in notifications"
/// should be one look at one lane's count.
///
/// The names are wire values, and declaration order is the order a review
/// screen lists them in.
///
/// This is the **union** of what the applications on this package emit, not a
/// menu each one picks from at runtime. An application that never opens a
/// socket simply never writes [ws], and `LogSummary.sourceCounts` omits a lane
/// with no records — so carrying a value you do not use costs nothing, and the
/// alternative (a per-application source set) would cost the exhaustive
/// switches and the fixed row order that make the review screen readable.
enum LogSource { http, ws, ui, notif, fgs, err, app }

/// Severity. [LogLevel.info] is the default and is omitted from the encoded
/// record; most lines are info, so spelling it out would pad the upload.
enum LogLevel { debug, info, warn, error }

/// Which isolate produced the stream. Each has its own heap, so each writes its
/// own file with its own header; the export merges them on absolute time
/// (`ts` + `t`), never on `t` alone.
///
/// The union again, and here the file suffix in [LogFileSink.fileFor] is a name
/// on the user's disk: renaming one would orphan a recording that is mid-flight
/// when the app updates. So the spellings are the ones already written —
/// [fgs] and [action] by bambuddy, [worker] by lubelogger.
enum LogStream { ui, fgs, action, worker }

/// Shape of the server host. A bare IP means a direct LAN setup, a name means
/// DNS or a reverse proxy in front — a distinction that explains a good share
/// of TLS reports and says nothing about who the user is.
enum HostKind { ip, name }

/// What we keep from the server URL: enough to reason about the setup, nothing
/// that identifies the user's network. The address itself never enters a log.
class ServerFingerprint {
  const ServerFingerprint({
    required this.scheme,
    required this.hostKind,
    this.port,
  });

  /// Returns null for anything unparseable — a fingerprint is a nice-to-have,
  /// never a reason to fail the recording.
  static ServerFingerprint? tryParse(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    return ServerFingerprint(
      scheme: uri.scheme,
      hostKind: _looksLikeIp(uri.host) ? HostKind.ip : HostKind.name,
      // Effective port, so 443 vs 8080 tells us whether a proxy is in play.
      port: uri.hasPort ? uri.port : _defaultPorts[uri.scheme],
    );
  }

  static const _defaultPorts = {'http': 80, 'https': 443, 'ws': 80, 'wss': 443};

  static final _ipish = RegExp(r'^[0-9.]+$|:');

  /// Digits-and-dots or anything with a colon (IPv6 literal). Deliberately
  /// loose — a wrong guess here only mislabels a hint, it can't leak.
  static bool _looksLikeIp(String host) => _ipish.hasMatch(host);

  final String scheme;
  final HostKind hostKind;
  final int? port;

  Map<String, Object?> toJson() => {
    'scheme': scheme,
    'host_kind': hostKind.name,
    if (port != null) 'port': port,
  };
}

/// First line of every log file: everything that is true for the whole session.
class LogHeader {
  const LogHeader({
    required this.ts,
    required this.session,
    required this.app,
    this.stream = LogStream.ui,
    this.os,
    this.locale,
    this.server,
    this.serverUrl,
    this.extra = const {},
  });

  /// Bumped when the record shape changes in a way a parser must know about.
  ///
  /// Adding a key to [extra] is not such a change: readers ignore what they do
  /// not know, and the relay accepts a fixed window of versions, so a bump costs
  /// a deployment before any build that sends one.
  static const formatVersion = 1;

  /// Keys this class owns. Everything else on a header line belongs to [extra]
  /// and is carried through untouched.
  static const _ownKeys = {
    'v',
    'ts',
    'session',
    'stream',
    'app',
    'os',
    'locale',
    'server',
    'scheme',
    'host_kind',
    'port',
  };

  /// Reads a header line back, or null when the line is not the header of
  /// [session].
  ///
  /// Exists for the background isolates: they do not build a header of their
  /// own, they continue the one the UI wrote, so they have to read it off disk.
  /// The checks are the point — a header write may fail silently while the
  /// writes after it succeed, so a stream's first line is not guaranteed to be
  /// a header, and accepting a *record* as one yields a header with no `ts`,
  /// which makes the merge drop the whole background stream from every report.
  ///
  /// Only `ts` and `app` are validated, because only those two are the merge's
  /// business. An application field that rides in [extra] — a flavor, an auth
  /// mode — is carried through as whatever the line held, including nothing.
  static LogHeader? tryParse(String line, {required String session}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on Object {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    final fields = decoded;
    if (fields.containsKey('t')) return null;
    if (fields['session'] != session) return null;
    final ts = DateTime.tryParse('${fields['ts']}');
    final app = fields['app'];
    if (ts == null || app is! String) return null;
    return LogHeader(
      ts: ts,
      session: session,
      app: app,
      stream: LogStream.values.firstWhere(
        (s) => s.name == fields['stream'],
        orElse: () => LogStream.ui,
      ),
      os: fields['os'] as String?,
      locale: fields['locale'] as String?,
      server: fields['server'] as String?,
      serverUrl: switch (fields['scheme']) {
        final String scheme => ServerFingerprint(
          scheme: scheme,
          hostKind: fields['host_kind'] == HostKind.ip.name
              ? HostKind.ip
              : HostKind.name,
          port: fields['port'] as int?,
        ),
        _ => null,
      },
      extra: {
        for (final e in fields.entries)
          if (!_ownKeys.contains(e.key)) e.key: e.value,
      },
    );
  }

  /// The same session, tagged as a different stream — what a background isolate
  /// writes at the top of its own file.
  LogHeader copyWith({LogStream? stream}) => LogHeader(
    ts: ts,
    session: session,
    app: app,
    stream: stream ?? this.stream,
    os: os,
    locale: locale,
    server: server,
    serverUrl: serverUrl,
    extra: extra,
  );

  /// Session identifier shared by every stream file of one recording.
  /// 128 random bits as hex — no uuid dependency for what is just a join key.
  static String newSessionId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  }

  /// Wall-clock start of this stream; every record's `t` is an offset from it.
  final DateTime ts;
  final String session;

  /// Full app version, e.g. `0.11.2+1102`.
  final String app;

  final LogStream stream;

  /// OS build string, e.g. what `Platform.operatingSystemVersion` reports.
  final String? os;

  final String? locale;

  /// Server version — never the server URL, which is the user's private host.
  final String? server;

  /// Scheme / host shape / port of the server URL. http-vs-https alone explains
  /// a whole class of reports, so it is a header field rather than something to
  /// dig out of redacted strings.
  final ServerFingerprint? serverUrl;

  /// The application's own header fields, spread flat alongside the ones above
  /// and read back untouched. A build flavor, a device model, an auth mode, a
  /// demo flag: each belongs to one app, none belongs here, and all of them are
  /// still plain top-level keys on the line.
  final Map<String, Object?> extra;

  Map<String, Object?> toJson() => {
    'v': formatVersion,
    'ts': ts.toUtc().toIso8601String(),
    'session': session,
    'stream': stream.name,
    'app': app,
    if (os != null) 'os': os,
    if (locale != null) 'locale': locale,
    if (server != null) 'server': server,
    if (serverUrl != null) ...serverUrl!.toJson(),
    for (final e in extra.entries)
      if (e.value != null && !_ownKeys.contains(e.key)) e.key: e.value,
  };

  String toJsonLine() => jsonEncode(toJson());
}

/// One event line. Extra [fields] are spread flat into the record so the
/// summariser can read `status` or `code` without unwrapping a payload object.
class LogEvent {
  LogEvent({
    required this.t,
    required this.src,
    required this.evt,
    this.lvl = LogLevel.info,
    Map<String, Object?> fields = const {},
  }) : fields = _usableFields(fields);

  /// Keys the record owns; a caller-supplied one is dropped rather than nested.
  /// `iso` is here although no record sets it — `mergeSessions` stamps it on the
  /// way out, and a probe reusing the name would make a record claim to come
  /// from an isolate it did not.
  static const reservedKeys = {'t', 'src', 'lvl', 'evt', 'iso'};

  /// Milliseconds since the header's `ts`.
  final int t;
  final LogSource src;
  final String evt;
  final LogLevel lvl;
  final Map<String, Object?> fields;

  static Map<String, Object?> _usableFields(Map<String, Object?> fields) {
    if (fields.isEmpty) return const {};
    return {
      for (final e in fields.entries)
        // Nulls are dropped so call sites can pass optional values
        // unconditionally without padding every line.
        if (e.value != null && !reservedKeys.contains(e.key)) e.key: e.value,
    };
  }

  Map<String, Object?> toJson() => {
    't': t,
    'src': src.name,
    if (lvl != LogLevel.info) 'lvl': lvl.name,
    'evt': evt,
    ...fields,
  };

  String toJsonLine() => jsonEncode(toJson());
}
