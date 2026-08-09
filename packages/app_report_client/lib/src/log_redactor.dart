/// Strips secrets at write time, because a crash before sending would ship the
/// buffer as it stands. Denylist by name and shape; [scrubSample] inverts it for
/// a record the server sent back. [ourKeys] is required so an application cannot
/// mistake this floor for the ceiling.
class LogRedactor {
  LogRedactor({
    required this.ourKeys,
    this.secretKeyPatterns = const [],
    this.valuePatterns = const [],
    this.freeTextKeys = const {},
    this.schemaKeys = const {},
    this.maxStringLength = 2000,
  });

  /// ~2000 chars is about 25 stack frames: enough to place a failure, small
  /// enough that one bad record cannot eat the ring buffer.
  final int maxStringLength;

  /// Exempt from the scrub: a server called `garage` would otherwise turn
  /// `garage.card` into `[HOST].card`. The pattern is the guard, not the name.
  final Map<String, RegExp> ourKeys;

  /// Secret whatever the shape, on top of [_baseSecretKey].
  final List<RegExp> secretKeyPatterns;

  /// Pattern → label. An app's credential format and hardware serials go here.
  final List<(RegExp, String)> valuePatterns;

  /// Fields the user writes into. [scrubSample] only.
  final Set<String> freeTextKeys;

  /// Kept verbatim inside a sample. [scrubSample] only.
  final Set<String> schemaKeys;

  /// Longest first at scrub time, so `printer-01.lan` wins over `printer-01`.
  final Map<String, String> _known = {};

  /// Shorter than this, a match is likelier coincidence than secret.
  static const _minKnownLength = 4;

  /// `key` is fenced so `keyboard` and `monkey` survive; `username` is here
  /// because a shared server would otherwise name other people in a public issue.
  static final _baseSecretKey = RegExp(
    r'(token|api_?key|(?:^|[^a-z0-9])key(?:$|[^a-z0-9])|secret|password|passwd'
    r'|authorization|cookie|username)',
    caseSensitive: false,
  );

  /// Keeps scheme and port, drops the host. The scheme list is the union of
  /// what the apps speak: an unused one costs nothing, a missing one leaks.
  static final _urlAuthority = RegExp(
    r'((?:https?|wss?|rtsps?)://)([^@/\s]+@)?([^:/\s?#]+)(:\d+)?',
    caseSensitive: false,
  );
  static final _jwt =
      RegExp(r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*');
  static final _queryToken = RegExp(
    r'([?&](?:token|access_token|api_?key|key)=)[^&\s]+',
    caseSensitive: false,
  );
  static final _email =
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b');

  /// Leading-zero octets are rejected, so `01.09.01.00` stays a version.
  static final _ipv4 = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)\.){3}'
    r'(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)\b',
  );

  bool _isSecretKey(String key) =>
      _baseSecretKey.hasMatch(key) ||
      secretKeyPatterns.any((p) => p.hasMatch(key));

  /// Null and too-short values are ignored.
  void remember(String? value, String label) {
    if (value == null || value.length < _minKnownLength) return;
    _known[value] = label;
  }

  /// Catches the host where no scheme surrounds it — a socket error reads
  /// "Failed host lookup: 'printer.lan'". Host only: `host:port` would swallow
  /// the port the authority pass keeps.
  void rememberServerUrl(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return;
    remember(uri.host, '[HOST]');
  }

  void forget(String? value) {
    if (value != null) _known.remove(value);
  }

  void forgetAll() => _known.clear();

  /// Null stays null: `[REDACTED]` on an absent value reads as "configured".
  static Object? _redacted(Object? value) =>
      value == null ? null : '[REDACTED]';

  Map<String, Object?> scrubFields(Map<String, Object?> fields) {
    if (fields.isEmpty) return const {};
    return {
      for (final e in fields.entries)
        e.key: _isSecretKey(e.key)
            ? _redacted(e.value)
            : _isOurs(e.key, e.value)
                ? e.value
                : scrub(e.value),
    };
  }

  bool _isOurs(String key, Object? value) {
    final shape = ourKeys[key];
    return shape != null && value is String && shape.hasMatch(value);
  }

  /// Recurses into maps and lists; other scalars pass through. [ourKeys] is
  /// honoured at every depth, not only at the top.
  Object? scrub(Object? value) {
    if (value is String) return scrubString(value);
    if (value is Map) {
      return {
        for (final e in value.entries)
          '${e.key}': _isSecretKey('${e.key}')
              ? _redacted(e.value)
              : _isOurs('${e.key}', e.value)
                  ? e.value
                  : scrub(e.value),
      };
    }
    if (value is List) return [for (final v in value) scrub(v)];
    return value;
  }

  String scrubString(String input) {
    if (input.isEmpty) return input;
    var out = input;

    // Longest first: a shorter known value may be a prefix of a longer one.
    final values = _known.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final value in values) {
      if (out.contains(value)) out = out.replaceAll(value, _known[value]!);
    }

    out = out
        .replaceAllMapped(
          _urlAuthority,
          (m) => '${m[1]}${m[2] == null ? '' : '[CREDENTIALS]@'}'
              '[HOST]${m[4] ?? ''}',
        )
        .replaceAll(_jwt, '[JWT]')
        .replaceAllMapped(_queryToken, (m) => '${m[1]}[REDACTED]')
        .replaceAll(_email, '[EMAIL]')
        .replaceAll(_ipv4, '[IP]');

    // Last, so a format overlapping a base pattern is not half-replaced twice.
    for (final (pattern, label) in valuePatterns) {
      out = out.replaceAll(pattern, label);
    }

    if (out.length > maxStringLength) {
      out = '${out.substring(0, maxStringLength)}…[clipped]';
    }
    return out;
  }

  /// A record the server sent back, with the user's content measured out.
  ///
  /// Inverted rule — a string survives only if it looks technical — because a
  /// denylist cannot cover a field a later server version invents. Field names
  /// stay: they are the API's schema. [key] is the field it came off.
  Object? scrubSample(Object? value, {String? key}) {
    if (value is String) {
      if (value.isEmpty) return value;
      final field = key?.toLowerCase();
      if (field != null && schemaKeys.contains(field)) return scrubString(value);
      return field != null && freeTextKeys.contains(field)
          ? '<str:${value.length}>'
          : _isTechnical(value)
              ? scrubString(value)
              : '<str:${value.length}>';
    }
    if (value is Map) {
      return {
        for (final e in value.entries)
          '${e.key}': _isSecretKey('${e.key}')
              ? _redacted(e.value)
              : scrubSample(e.value, key: '${e.key}'),
      };
    }
    // Head only: the second entry says nothing the first did not. The key
    // travels along — a list of tags is as much the user's as the field.
    if (value is List) {
      return [for (final v in value.take(3)) scrubSample(v, key: key)];
    }
    return value;
  }

  /// Deliberately not "short alphanumeric" — that is a licence plate.
  static bool _isTechnical(String value) =>
      value.length <= 40 &&
      (_number.hasMatch(value) ||
          _boolean.hasMatch(value) ||
          _dateish.hasMatch(value) ||
          (value.length <= 24 && _enumish.hasMatch(value)));

  static final _number = RegExp(r'^-?[\d]+([.,][\d]+)?$');
  static final _boolean = RegExp(r'^(true|false)$', caseSensitive: false);

  /// Any separator: the point is to see which format the server chose.
  static final _dateish = RegExp(
    r'^\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}([ T][\d:.+Zz-]*)?$',
  );

  /// No digits (keeps plates out), no spaces (keeps a typed sentence out).
  static final _enumish = RegExp(r'^[A-Za-z]+([_-][A-Za-z]+)*$');
}
