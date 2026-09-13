/// A server address the way a user typed it, made into a base URL: trimmed,
/// given [defaultScheme] when it names none, and stripped of trailing slashes
/// and then of [apiPath].
///
/// [defaultScheme] is the application's call, and the two differ on purpose: a
/// server usually kept on a LAN is plain `http`, one usually reverse-proxied is
/// `https`. Either way the guess is corrected by [baseUrlFromReached] once a
/// probe has followed the server's redirect. Empty input stays empty rather
/// than becoming a bare scheme.
String normalizeBaseUrl(
  String raw, {
  required String defaultScheme,
  String? apiPath,
}) {
  var url = raw.trim();
  if (url.isEmpty) return url;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = '$defaultScheme://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  if (apiPath != null && url.endsWith(apiPath)) {
    url = url.substring(0, url.length - apiPath.length);
  }
  return url;
}

/// The base URL a probe actually reached, honouring any http→https (or host)
/// redirect the HTTP client followed transparently.
///
/// The bug this exists for: a bare host is normalized to `http://`, the server
/// redirects the probe to `https://`, and everything built from the stored base
/// afterwards — a WebSocket above all — goes to a scheme the server does not
/// answer. A mocked adapter follows no redirects, so no test that mocks one
/// can catch it.
///
/// [reached] is the final URI of the probe (e.g. `Response.realUri`);
/// [endpointSuffix] is the path that was appended to the base. It is stripped
/// off `origin + path`, so a reverse-proxy path prefix survives. Falls back to
/// [requested] when [reached] is null or does not end with the suffix.
String baseUrlFromReached(
  Uri? reached, {
  required String requested,
  required String endpointSuffix,
}) {
  if (reached == null) return requested;
  final full = reached.origin + reached.path;
  if (full.endsWith(endpointSuffix)) {
    return full.substring(0, full.length - endpointSuffix.length);
  }
  return requested;
}
