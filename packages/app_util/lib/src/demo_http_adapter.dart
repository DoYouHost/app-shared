import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Result of a routed demo request: HTTP status and a JSON-encodable body, or a
/// [DemoFile].
typedef DemoResult = ({int status, Object? body});

/// Answers one request the way the application's in-process fake server would.
/// [body] is the request payload already decoded from JSON (a map, a list, or
/// null).
typedef DemoHandler = DemoResult Function(String method, Uri uri, Object? body);

/// A response that is a file rather than a document.
///
/// Carried as the result's `body` so every other route keeps its two-field
/// shape; [DemoHttpClientAdapter] serves this one as bytes with its own content
/// type instead of JSON-encoding it.
class DemoFile {
  const DemoFile(this.bytes, this.contentType);

  final Uint8List bytes;
  final String contentType;
}

/// Dio [HttpClientAdapter] for demo mode: routes every request into [handle]
/// instead of the network.
///
/// Installed on the authenticated Dio, so every consumer of it — repositories,
/// a background isolate — is covered without knowing demo mode exists.
class DemoHttpClientAdapter implements HttpClientAdapter {
  DemoHttpClientAdapter(
    this.handle, {
    this.uploads,
    this.latency = const Duration(milliseconds: 120),
  });

  final DemoHandler handle;

  /// Answers a multipart upload, whose body is not JSON and so cannot reach
  /// [handle] as one. Without it [handle] gets the request with a null body.
  final DemoResult Function(FormData form)? uploads;

  /// Simulated network latency, so the UI's loading states stay visible.
  final Duration latency;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(latency);
    final data = options.data;
    final result = data is FormData && uploads != null
        ? uploads!(data)
        : handle(options.method.toUpperCase(), options.uri, _decoded(data));
    final file = result.body;
    if (file is DemoFile) {
      // Content-Length is what makes a download's progress bar move — without
      // it Dio reports -1 as the total.
      return ResponseBody.fromBytes(
        file.bytes,
        result.status,
        headers: {
          Headers.contentTypeHeader: [file.contentType],
          Headers.contentLengthHeader: ['${file.bytes.length}'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(result.body),
      result.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  /// The payload as Dio holds it — a map, a list, or a JSON string — decoded.
  static Object? _decoded(Object? data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return null;
      }
    }
    if (data is FormData) return null;
    return data;
  }

  @override
  void close({bool force = false}) {}
}
