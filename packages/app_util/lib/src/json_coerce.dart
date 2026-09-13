import 'package:app_diagnostics/app_diagnostics.dart';

// Tolerant JSON coercion for hand-written `fromJson` factories and
// `@JsonKey(fromJson: ...)`.
//
// A plain cast (`e as Map<String, dynamic>`, `json['n'] as int`) throws on the
// first record a server spells differently, and the throw takes the whole list
// or the whole parent record with it. Everything here answers a fallback
// instead, and the list parsers drop one bad record rather than the response.
// Both applications had grown their own `_toInt`/`_toDouble` per model file,
// in the same shape; this is that shape, once.

/// Tolerant parse of a **calendar date**, kept as the date the server wrote.
///
/// A date the user picked as a date — a due date, a service date — is often
/// stored in a datetime column and sent back as midnight. Converting that
/// midnight across zones moves it to the previous day for every device west of
/// UTC, so the date is taken as written and rebuilt as a local midnight. There
/// is no zone conversion, because a due date is not an instant.
DateTime? calendarDateFromJson(dynamic value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value.trim());
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// Inverse of [calendarDateFromJson]: the date as the user picked it, with no
/// zone conversion. `toIso8601String` cannot stand in — it would carry a time,
/// and on a UTC-negative device `toUtc` first would move the day.
String calendarDateToJson(DateTime date) =>
    '${_pad(date.year, 4)}-${_pad(date.month, 2)}-${_pad(date.day, 2)}';

String _pad(int value, int width) => value.toString().padLeft(width, '0');

/// Tolerant list parse: skips elements that aren't objects, and skips (rather
/// than propagates) any element [fromJson] itself fails to parse — one
/// malformed record drops just that entry instead of the whole list.
///
/// Every skip is also recorded while a diagnostic recording runs. Tolerance is
/// what keeps one bad record from emptying a screen, and it is also what makes
/// a whole screen go empty in silence when the server renames a field every
/// record has — that shows up as a 200 with nothing on screen, which is
/// indistinguishable from "there was nothing to show" unless the drop says so
/// itself.
List<T> parseJsonList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) return const [];
  final out = <T>[];
  var dropped = 0;
  String? cause;
  for (final item in value) {
    try {
      // `Map`, not `Map<String, dynamic>`: a record that did not come straight
      // out of `jsonDecode` — one relayed over a platform channel, which Dart
      // types as `Map<Object?, Object?>`, or built by an untyped `Map.from` —
      // is an object all the same. Testing for the exact type would drop it
      // silently.
      if (item is! Map) {
        dropped++;
        cause ??= 'not an object: ${item.runtimeType}';
        continue;
      }
      out.add(fromJson(asJsonRecord(item)));
    } on Object catch (e) {
      dropped++;
      // The first failure only: a field the server renamed fails the same way
      // on every record, and one copy of the message names the field.
      cause ??= e.toString();
      continue;
    }
  }
  if (dropped > 0) {
    DiagnosticRecorder.active?.add(
      LogSource.app,
      'parse_drop',
      lvl: LogLevel.warn,
      fields: {
        'type': T.toString(),
        'n': dropped,
        'of': value.length,
        'cause': cause,
      },
    );
  }
  return out;
}

/// One decoded record as the generated `fromJson` factories want it. Free when
/// the value already has that type, which is the case for everything
/// `jsonDecode` produced.
Map<String, dynamic> asJsonRecord(Map<dynamic, dynamic> value) =>
    value is Map<String, dynamic> ? value : Map<String, dynamic>.from(value);

/// [parseJsonList] for a field whose **absence** has to stay distinguishable
/// from an empty list, and which therefore cannot fall back to `const []`.
///
/// The case it exists for is a partial update merged over the last known
/// state: there a null means "this frame did not mention it" and inherits,
/// while an empty list is news. Answering an empty list for a frame that simply
/// did not carry the field would blank what it describes on every update.
List<T>? parseJsonListOrNull<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) => value is List ? parseJsonList(value, fromJson) : null;

/// One tolerant nested record: anything that is not an object, and any record
/// [fromJson] itself chokes on, reads as absent rather than throwing through
/// the parent.
T? parseJsonObjectOrNull<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! Map) return null;
  try {
    return fromJson(asJsonRecord(value));
  } on Object catch (e) {
    DiagnosticRecorder.active?.add(
      LogSource.app,
      'parse_drop',
      lvl: LogLevel.warn,
      fields: {'type': T.toString(), 'n': 1, 'of': 1, 'cause': e.toString()},
    );
    return null;
  }
}

/// Tolerant map keyed by a numeric id the server stringifies (`{"0": …}`), with
/// absence kept distinct from emptiness for the same reason
/// [parseJsonListOrNull] is. [valueOf] reads one entry; an entry whose key or
/// value it cannot read is dropped rather than guessed at.
Map<int, V>? parseJsonMapByIdOrNull<V>(
  dynamic value,
  V? Function(dynamic value) valueOf,
) {
  if (value is! Map) return null;
  final out = <int, V>{};
  value.forEach((key, raw) {
    final id = toIntOrNull(key);
    final entry = valueOf(raw);
    if (id != null && entry != null) out[id] = entry;
  });
  return out;
}

/// Tolerant `int?` coercion: accepts `int`, other `num` (truncated), or a
/// parseable `String`; anything else (including non-numeric strings) → `null`.
int? toIntOrNull(dynamic value) => switch (value) {
  int n => n,
  num n => n.toInt(),
  String s => int.tryParse(s),
  _ => null,
};

/// [toIntOrNull] with a `0` fallback — for fields the server always sends,
/// where coercion failure should read as "0" rather than propagate `null`.
int toInt(dynamic value) => toIntOrNull(value) ?? 0;

/// Tolerant `double?` coercion: accepts any `num` or a parseable `String`.
double? toDoubleOrNull(dynamic value) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

/// [toDoubleOrNull] with a `0` fallback.
double toDouble(dynamic value) => toDoubleOrNull(value) ?? 0;

/// Tolerant non-empty `String?`: non-strings, blank, or whitespace-only → `null`.
String? toStringOrNull(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Tolerant `Map<String, int>` coercion — server aggregates keyed by a
/// stringified id.
Map<String, int> toIntMap(dynamic value) {
  if (value is! Map) return const {};
  final out = <String, int>{};
  value.forEach((key, v) => out['$key'] = toInt(v));
  return out;
}

/// Tolerant `Map<String, double>` coercion, see [toIntMap].
Map<String, double> toDoubleMap(dynamic value) {
  if (value is! Map) return const {};
  final out = <String, double>{};
  value.forEach((key, v) => out['$key'] = toDouble(v));
  return out;
}

/// Tolerant `Map<String, String>` coercion, see [toIntMap]. An entry whose
/// value is not a non-blank string is dropped rather than kept as an empty
/// label — the caller's own fallback names that row better than nothing does.
Map<String, String> toStringMap(dynamic value) {
  if (value is! Map) return const {};
  final out = <String, String>{};
  value.forEach((key, v) {
    final text = toStringOrNull(v);
    if (text != null) out['$key'] = text;
  });
  return out;
}

/// Tolerant `bool` coercion with a `false` fallback: accepts a real boolean,
/// a number (`0` is false) and the strings servers use for one. False is the
/// fallback because a flag nobody reported is, to every caller so far, a flag
/// that is not set.
bool toBoolOrFalse(dynamic value) => switch (value) {
  bool b => b,
  num n => n != 0,
  String s => s.toLowerCase() == 'true' || s == '1',
  _ => false,
};

/// Tolerant `List<String>` coercion: keeps only string elements.
List<String> toStringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
