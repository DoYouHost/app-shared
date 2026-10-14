/// [raw] as a web address, or null when it is anything else.
///
/// A link a server stores was typed by some user of that server. Handed to
/// `launchUrl` as it is, an `intent:`, `market:` or custom-scheme link starts
/// whatever app on this phone claims it, so only an http(s) address with a host
/// may leave the app.
Uri? webLinkOrNull(String? raw) {
  final uri = Uri.tryParse(raw?.trim() ?? '');
  if (uri == null || uri.host.isEmpty) return null;
  return uri.isScheme('http') || uri.isScheme('https') ? uri : null;
}
