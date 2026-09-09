import 'dart:convert';

import 'package:dio/dio.dart';

import 'diagnostic_recorder.dart';
import 'log_event.dart';
import 'log_store.dart';

/// Which answers are worth keeping a sample of, and how much of one.
///
/// All of it is per-application. Which routes carry the app's content is a
/// question about that app's API; which ones must never be sampled is a
/// question about where its credentials travel; and the size of a record worth
/// reading was measured against real responses, per app. Nothing here has a
/// value this package could defend, so nothing here has a default beyond
/// "sample nothing", which is the only safe thing to do without being told.
class HttpProbeConfig {
  const HttpProbeConfig({
    this.sampledPaths,
    this.neverSampled,
    this.maxSampleChars = 4 * 1024,
    this.maxClippedChars = 1900,
    this.maxBodyChars = 300,
    this.redactSamples = true,
    this.fieldsOf,
    this.pathOf,
  });

  /// Endpoints whose answers are the app's content. Null samples nothing.
  final RegExp? sampledPaths;

  /// Checked before [sampledPaths] and wins over it — where credentials travel.
  final RegExp? neverSampled;

  /// Above this the sample is logged in a clipped, escaped form of at most
  /// [maxClippedChars]. Keep [maxClippedChars] under the redactor's own
  /// `maxStringLength`, so such a clip is marked once and not twice.
  final int maxSampleChars;
  final int maxClippedChars;

  /// Ceiling on an error body. A short `detail` is the app's; anything longer
  /// is usually a proxy's HTML error page, which names the proxy in its first
  /// few tags.
  final int maxBodyChars;

  /// Whether a sample goes through [LogRedactor.scrubSample] before it is
  /// measured, compared or written. On unless the application can say why a
  /// route's payload holds nothing of anybody's.
  final bool redactSamples;

  /// Fields to record on every request of this app's own — an entity id the
  /// reports keep turning on. Never anything the user typed.
  final Map<String, Object?> Function(RequestOptions options)? fieldsOf;

  /// Reduces a request path to the only form allowed in a record. Identity
  /// when null, which is right only for an API whose every segment is a route
  /// word or an id — see `loggablePath` for the other case.
  final String Function(String path)? pathOf;
}

/// Records every call the app makes to its server: method, path, status, how
/// long it took, and what failed when it failed. "The app is broken" usually
/// turns out to be a 502 or a handshake that never completed, and the UI shows
/// the same empty card either way.
///
/// Install it on every Dio the app builds, so it also covers the login calls
/// that run before there is a client, and a background isolate's own client.
class HttpProbe extends Interceptor {
  HttpProbe({this.config = const HttpProbeConfig()});

  final HttpProbeConfig config;

  /// `extra` survives redirects and the auth retry, which re-send the very same
  /// [RequestOptions].
  static const _startedAtKey = 'diagnosticsStartedAt';

  /// Keyed by method, path and the query's *hash* — two statuses behind one
  /// path must dedupe against themselves, and the query never reaches a record.
  static final Map<String, String> _lastSample = {};

  static void openSession() => _lastSample.clear();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Stamped whether or not a recording runs: starting one mid-flight is the
    // normal case, and an unstamped response would log without a duration.
    options.extra[_startedAtKey] = DateTime.now().millisecondsSinceEpoch;
    // "Did my save even leave the phone" has no other witness; a GET that never
    // returns shows up as a response missing from the polling around it.
    if (!_isRead(options.method)) {
      DiagnosticRecorder.active?.add(
        LogSource.http,
        'request',
        lvl: LogLevel.debug,
        fields: {
          'method': options.method,
          'path': _pathOf(options),
          ..._fieldsOf(options),
        },
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Local null check rather than `?.`: the sample below must be built (and
    // the fingerprint kept) only while something is recording.
    final store = DiagnosticRecorder.active;
    if (store != null) {
      final status = response.statusCode;
      store.add(
        LogSource.http,
        'response',
        // A 4xx only reaches here when the call opted out of status validation.
        lvl: status != null && status >= 400 ? LogLevel.warn : LogLevel.info,
        fields: {
          'method': response.requestOptions.method,
          'path': _pathOf(response.requestOptions),
          ..._fieldsOf(response.requestOptions),
          'status': status,
          'ms': _elapsedMs(response.requestOptions),
          // "The queue is empty" and "the queue came back full and the app
          // dropped all of it" are the same 200 without this.
          'n': _countOf(response.data),
          // dio hands back a null body for an empty response claiming to be
          // JSON, which the data layer reads as an empty list — the one way a
          // truncated answer reaches a screen as "there is nothing here"
          // instead of as an error.
          'empty':
              _isRead(response.requestOptions.method) && response.data == null
              ? true
              : null,
          ..._sampleOf(store, response),
        },
      );
    }
    handler.next(response);
  }

  /// [LogRedactor.scrubSample], not the ordinary field pass: a denylist cannot
  /// cover a field a later server version adds. Records go in as a map so the
  /// redactor still checks names at every depth.
  Map<String, Object?> _sampleOf(LogStore store, Response<dynamic> response) {
    final sampled = config.sampledPaths;
    if (sampled == null) return const {};
    final options = response.requestOptions;
    final path = _pathOf(options);
    if (config.neverSampled?.hasMatch(path) ?? false) return const {};
    if (!sampled.hasMatch(path)) return const {};
    final record = _firstRecord(response.data);
    if (record == null) return const {};

    // Scrubbed before it is measured or compared, or a change the redactor
    // removes would still count as a change and every poll would log a "new"
    // record. Non-null by construction: the map branch always answers with one.
    final sample = config.redactSamples
        ? store.redactor.scrubSample(record)!
        : record;
    final encoded = _encoded(sample);
    final key = '${options.method} $path?${options.uri.query.hashCode}';
    final fingerprint = _fingerprintOf(encoded, _countOf(response.data));
    if (_lastSample[key] == fingerprint) return const {'same': true};
    _lastSample[key] = fingerprint;
    return {
      'first': encoded.length > config.maxSampleChars
          ? '${encoded.substring(0, config.maxClippedChars)}…'
          : sample,
    };
  }

  /// What "the same answer" means, given a server that restamps every record it
  /// sends. Timestamps are compared out but never logged out, and the count is
  /// part of the comparison — a queue that grew from one item to two answers
  /// with the same first record.
  static String _fingerprintOf(String encoded, int? count) {
    final stable = _timestamps.hasMatch(encoded)
        ? encoded.replaceAll(_timestamps, '"<ts>"')
        : encoded;
    return '$count:$stable';
  }

  /// Matched by ISO-8601 shape rather than by field name, so a server that adds
  /// another such field needs no change here.
  static final _timestamps = RegExp(
    r'"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?"',
  );

  /// A list's first entry, or the object itself. An empty list, a list of
  /// scalars, an image or a bare string has no record to show.
  static Map<String, dynamic>? _firstRecord(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is List && data is! List<int>) {
      final first = data.isEmpty ? null : data.first;
      return first is Map<String, dynamic> ? first : null;
    }
    return null;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    // `HandshakeException` versus `SocketException` separates "TLS refused"
    // from "nothing listening there", which dio lumps into `connectionError`.
    final cause = err.error?.runtimeType.toString();
    final store = DiagnosticRecorder.active;
    store?.add(
      LogSource.http,
      'error',
      lvl: _levelOf(err),
      fields: {
        'method': err.requestOptions.method,
        'path': _pathOf(err.requestOptions),
        ..._fieldsOf(err.requestOptions),
        'type': err.type.name,
        'status': status,
        'ms': _elapsedMs(err.requestOptions),
        'cause': cause,
        // dio's message only restates the status when there is a response, so
        // it earns its place exactly when there is none.
        'msg': status == null ? _reasonOf(err, cause) : null,
        'body': status == null ? null : _bodyPreview(err.response?.data, store),
      },
    );
    handler.next(err);
  }

  /// The underlying exception before dio's wrapper: `SocketException` carries
  /// the OS error and errno, which dio drops when it reformats. The class name
  /// is already the `cause`, and dio's closing sentence goes because repeating
  /// it seventy-eight characters at a time was, in an offline session, the
  /// single largest thing in the log.
  static String? _reasonOf(DioException err, String? cause) {
    final text = (err.error?.toString() ?? err.message)?.trim();
    if (text == null || text.isEmpty) return null;
    final withoutClass = cause != null && text.startsWith('$cause: ')
        ? text.substring(cause.length + 2)
        : text;
    return withoutClass.replaceFirst(_dioBoilerplate, '').trimRight();
  }

  /// dio appends this to every message it builds itself.
  static final _dioBoilerplate = RegExp(
    r'\s*This indicates an error which most likely cannot be solved by the '
    r'library\.?$',
  );

  /// A downloaded image is a `List<int>` whose length is a byte count, and
  /// reported as `n` it would read as "the server sent 34 000 records".
  static int? _countOf(Object? data) =>
      data is List && data is! List<int> ? data.length : null;

  static bool _isRead(String method) {
    final upper = method.toUpperCase();
    return upper == 'GET' || upper == 'HEAD';
  }

  /// `uri` resolves the relative path against the base URL, which drops the
  /// host and the query string — where the tokens live — with it. What is left
  /// still goes through [HttpProbeConfig.pathOf], because a path can carry the
  /// user's own text in a segment and no redactor catches that: it is a path,
  /// not a field.
  /// The application's own per-request fields, and never a throw: this runs on
  /// every request, and an extractor tripping over an odd URL must not be the
  /// reason a call fails.
  Map<String, Object?> _fieldsOf(RequestOptions options) {
    final read = config.fieldsOf;
    if (read == null) return const {};
    try {
      return read(options);
    } on Object {
      return const {};
    }
  }

  String _pathOf(RequestOptions options) {
    final path = options.uri.path;
    return config.pathOf?.call(path) ?? path;
  }

  static int? _elapsedMs(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! int) return null;
    final ms = DateTime.now().millisecondsSinceEpoch - startedAt;
    // A clock moved backwards must not produce a response arriving before it
    // was asked for.
    return ms < 0 ? 0 : ms;
  }

  static LogLevel _levelOf(DioException err) {
    // Usually the app's own doing — a screen closed while loading.
    if (err.type == DioExceptionType.cancel) return LogLevel.info;
    // No response at all is ours to explain; a status means the server did
    // answer, and the summariser groups those by status anyway.
    return err.response == null ? LogLevel.error : LogLevel.warn;
  }

  /// JSON is measured like a sampled record — FastAPI's 422 echoes the
  /// offending input verbatim, while `type` and `loc` survive, which is what
  /// the body is opened for. Non-JSON is left alone: a proxy's HTML error page
  /// names the proxy and holds nothing of anybody's.
  String? _bodyPreview(Object? data, LogStore store) {
    if (data == null) return null;
    // A download that failed; encoding it would spell out an array of numbers.
    if (data is List<int>) return '<${data.length} bytes>';
    final text = data is String
        ? data
        : _encoded(
            config.redactSamples
                ? (store.redactor.scrubSample(data) ?? data)
                : data,
          );
    if (text.isEmpty) return null;
    return text.length > config.maxBodyChars
        ? '${text.substring(0, config.maxBodyChars)}…'
        : text;
  }

  static String _encoded(Object data) {
    try {
      return jsonEncode(data);
    } on Object {
      // A streamed or otherwise unencodable body must not fail the request it
      // describes; its type is all we can say about it.
      return '<${data.runtimeType}>';
    }
  }
}
