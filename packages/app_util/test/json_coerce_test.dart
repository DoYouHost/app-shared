import 'dart:convert';

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:app_report_client/app_report_client.dart';
import 'package:app_util/app_util.dart';
import 'package:flutter_test/flutter_test.dart';

/// A record with one required field, which is all a test of tolerance needs: a
/// payload without `position` makes the cast throw the way a renamed server
/// field does.
class _Item {
  const _Item(this.id, this.position);

  factory _Item.fromJson(Map<String, dynamic> json) =>
      _Item(json['id'] as int, json['position'] as int);

  final int id;
  final int position;
}

class _MemorySessions implements DiagnosticsSessionStore {
  String? _session;

  @override
  String? loadSession() => _session;

  @override
  Future<void> saveSession(String? session) async => _session = session;
}

void main() {
  // Starting a recording attaches the interaction probe to the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiagnosticRecorder recorder;

  setUp(() {
    recorder = DiagnosticRecorder(
      sessions: _MemorySessions(),
      redactor: () => LogRedactor(ourKeys: {'id': RegExp(r'^\w+$')}),
      loadFacts: () async => const SessionFacts(app: '1.0.0+1'),
      sessionDuration: const Duration(minutes: 30),
      sessionBytes: 1024 * 1024,
      resolveDirectory: () async => null,
    );
    addTearDown(recorder.discard);
  });

  Future<List<Map<String, dynamic>>> stopAndParse() async {
    final jsonl = await recorder.stop();
    return [
      for (final line in const LineSplitter().convert(jsonl))
        jsonDecode(line) as Map<String, dynamic>,
    ];
  }

  group('calendarDateFromJson', () {
    test('a date stays that date, with no zone shift', () {
      // A due date on the 5th is the 5th everywhere. Converted as an instant,
      // UTC midnight would slide to the 4th for anyone west of UTC.
      for (final raw in [
        '2026-08-05',
        '2026-08-05T00:00:00',
        '2026-08-05T00:00:00Z',
      ]) {
        final d = calendarDateFromJson(raw)!;
        expect([d.year, d.month, d.day], [2026, 8, 5], reason: raw);
        expect(d.isUtc, isFalse);
      }
    });

    test('what is not a date → null', () {
      for (final junk in [null, '', 'someday', 7]) {
        expect(calendarDateFromJson(junk), isNull, reason: 'input: $junk');
      }
    });
  });

  group('calendarDateToJson', () {
    test('pads to the shape a server parses', () {
      expect(calendarDateToJson(DateTime(2026, 8, 5)), '2026-08-05');
      expect(calendarDateToJson(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('keeps the day the user picked, whatever the time of day', () {
      // The reason `toIso8601String`/`toUtc` cannot stand in: a local midnight
      // is the previous day in UTC for every device west of it.
      expect(calendarDateToJson(DateTime(2026, 8, 5, 0, 0)), '2026-08-05');
      expect(calendarDateToJson(DateTime(2026, 8, 5, 23, 59)), '2026-08-05');
    });

    test('round-trips through the parser it is the inverse of', () {
      final date = DateTime(2026, 3, 7);
      expect(calendarDateFromJson(calendarDateToJson(date)), date);
    });
  });

  group('parseJsonList', () {
    test('skips the broken element and parses the rest', () {
      final items = parseJsonList([
        {'id': 1, 'position': 1},
        {'id': 2},
        {'id': 3, 'position': 2},
      ], _Item.fromJson);

      expect(items.map((i) => i.id), [1, 3]);
    });

    test(
      'records the dropped elements: how many, of how many, and why',
      () async {
        await recorder.start();

        // The whole list dropped — exactly the case where the screen looks empty
        // and the server answered 200 with data in it.
        final items = parseJsonList([
          {'id': 1},
          {'id': 2},
        ], _Item.fromJson);

        expect(items, isEmpty);
        final drop = (await stopAndParse()).firstWhere(
          (r) => r['evt'] == 'parse_drop',
        );
        expect(drop['src'], 'app');
        expect(drop['lvl'], 'warn');
        expect(drop['type'], '_Item');
        expect(drop['n'], 2);
        expect(drop['of'], 2);
        expect(
          drop['cause'],
          contains('Null'),
          reason: 'the cause names the cast that failed',
        );
      },
    );

    test('an element that is not an object is reported too', () async {
      await recorder.start();

      parseJsonList(['not an object'], _Item.fromJson);

      final drop = (await stopAndParse()).firstWhere(
        (r) => r['evt'] == 'parse_drop',
      );
      expect(drop['n'], 1);
      expect(drop['cause'], contains('not an object'));
    });

    test('nothing dropped — no record at all', () async {
      await recorder.start();

      parseJsonList([
        {'id': 1, 'position': 1},
      ], _Item.fromJson);

      expect(
        (await stopAndParse()).where((r) => r['evt'] == 'parse_drop'),
        isEmpty,
      );
    });

    test('reads a record whose static key type is not String', () {
      // What a platform channel hands back (`Map<Object?, Object?>`) and what an
      // untyped `Map.from` builds. An exact `is Map<String, dynamic>` test would
      // drop them as "not an object" without a word.
      final items = parseJsonList(<dynamic>[
        <Object?, Object?>{'id': 1, 'position': 1},
      ], _Item.fromJson);

      expect(items.single.id, 1);
    });

    test('anything that is not a list is an empty one', () {
      expect(parseJsonList(null, _Item.fromJson), isEmpty);
      expect(parseJsonList({'id': 1}, _Item.fromJson), isEmpty);
    });
  });

  group('parseJsonListOrNull', () {
    test('tells an absent list apart from an empty one', () {
      expect(parseJsonListOrNull(null, _Item.fromJson), isNull);
      expect(parseJsonListOrNull('not a list', _Item.fromJson), isNull);
      expect(parseJsonListOrNull(<dynamic>[], _Item.fromJson), isEmpty);
    });

    test('drops one bad record rather than the list', () {
      final items = parseJsonListOrNull([
        {'id': 1, 'position': 1},
        {'id': 2},
      ], _Item.fromJson);

      expect(items!.map((i) => i.id), [1]);
    });
  });

  group('parseJsonObjectOrNull', () {
    test('parses a nested record', () {
      final item = parseJsonObjectOrNull({
        'id': 7,
        'position': 1,
      }, _Item.fromJson);

      expect(item!.id, 7);
    });

    test('answers null for anything that is not an object', () {
      for (final junk in [null, 'text', 3, <dynamic>[]]) {
        expect(
          parseJsonObjectOrNull(junk, _Item.fromJson),
          isNull,
          reason: 'input: $junk',
        );
      }
    });

    test(
      'a record the factory chokes on reads as absent, and is recorded',
      () async {
        // Not a throw: the field is one part of its parent, and losing the
        // parent over it would take everything else in it down too.
        await recorder.start();

        final item = parseJsonObjectOrNull({'id': 1}, _Item.fromJson);

        expect(item, isNull);
        final drop = (await stopAndParse()).firstWhere(
          (r) => r['evt'] == 'parse_drop',
        );
        expect(drop['type'], '_Item');
        expect(drop['n'], 1);
      },
    );
  });

  group('parseJsonMapByIdOrNull', () {
    test('reads the stringified numeric keys a server sends', () {
      final map = parseJsonMapByIdOrNull({'0': 1, '1': 0}, toIntOrNull);

      expect(map, {0: 1, 1: 0});
    });

    test('keeps absence apart from emptiness', () {
      expect(parseJsonMapByIdOrNull(null, toIntOrNull), isNull);
      expect(parseJsonMapByIdOrNull('not a map', toIntOrNull), isNull);
      expect(parseJsonMapByIdOrNull(<String, dynamic>{}, toIntOrNull), isEmpty);
    });

    test('drops an entry it cannot read either half of', () {
      // A key that is not a number would otherwise have to be guessed at, and a
      // guessed id addresses the wrong thing.
      final map = parseJsonMapByIdOrNull({
        '0': 1,
        'left': 1,
        '2': 'not a number',
      }, toIntOrNull);

      expect(map, {0: 1});
    });
  });

  group('numbers', () {
    test('toIntOrNull takes ints, truncates other numbers, parses strings', () {
      expect(toIntOrNull(3), 3);
      expect(toIntOrNull(3.9), 3);
      expect(toIntOrNull('42'), 42);
    });

    test('toIntOrNull answers null for what it cannot read', () {
      for (final junk in [null, '', '4.5', 'four', true, <dynamic>[]]) {
        expect(toIntOrNull(junk), isNull, reason: 'input: $junk');
      }
    });

    test('toInt falls back to zero', () {
      expect(toInt('four'), 0);
      expect(toInt(null), 0);
      expect(toInt('7'), 7);
    });

    test('toDoubleOrNull takes any number and a parseable string', () {
      expect(toDoubleOrNull(3), 3.0);
      expect(toDoubleOrNull(2.5), 2.5);
      expect(toDoubleOrNull('2.5'), 2.5);
      expect(toDoubleOrNull('two'), isNull);
      expect(toDoubleOrNull(null), isNull);
    });

    test('toDouble falls back to zero', () {
      expect(toDouble('two'), 0.0);
      expect(toDouble('1.25'), 1.25);
    });
  });

  group('strings', () {
    test('toStringOrNull trims, and blank is nothing', () {
      expect(toStringOrNull('  name  '), 'name');
      expect(toStringOrNull('   '), isNull);
      expect(toStringOrNull(''), isNull);
      expect(toStringOrNull(42), isNull);
    });

    test('toStringList keeps only the strings', () {
      expect(toStringList(['a', 1, null, 'b']), ['a', 'b']);
      expect(toStringList('a'), isEmpty);
    });
  });

  group('maps', () {
    test('toIntMap and toDoubleMap stringify keys and coerce values', () {
      expect(toIntMap({1: '3', '2': 4.7}), {'1': 3, '2': 4});
      expect(toDoubleMap({'a': '1.5', 'b': null}), {'a': 1.5, 'b': 0.0});
      expect(toIntMap(null), isEmpty);
      expect(toDoubleMap(const []), isEmpty);
    });

    test(
      'toStringMap keeps the keys as strings and drops what is not a label',
      () {
        final names = toStringMap(const {
          '3': 'Ultron',
          4: 'Bender',
          '5': null,
          '6': '   ',
          '7': 42,
        });

        expect(names['3'], 'Ultron');
        expect(names['4'], 'Bender');
        // A blank or non-string value is no label: the caller's own fallback
        // names that row better than an empty string would.
        expect(names.keys, ['3', '4']);
      },
    );

    test('a missing or non-map field is an empty map, never a throw', () {
      expect(toStringMap(null), isEmpty);
      expect(toStringMap('nope'), isEmpty);
      expect(toStringMap(const []), isEmpty);
    });
  });

  group('toBoolOrFalse', () {
    test('accepts the spellings servers use', () {
      expect(toBoolOrFalse(true), isTrue);
      expect(toBoolOrFalse(1), isTrue);
      expect(toBoolOrFalse('true'), isTrue);
      expect(toBoolOrFalse('TRUE'), isTrue);
      expect(toBoolOrFalse('1'), isTrue);
    });

    test('anything it cannot read is false, never a throw', () {
      for (final junk in [null, 0, 'false', 'yes', '', <dynamic>[]]) {
        expect(toBoolOrFalse(junk), isFalse, reason: 'input: $junk');
      }
    });
  });
}
