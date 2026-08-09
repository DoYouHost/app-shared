import 'dart:convert';

import 'package:app_report_client/app_report_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// The redactor against answers the real servers actually send.
///
/// The other redactor suite tests the rules one at a time, which is how a rule
/// gets written and also how a rule gets believed: every one of them passes on
/// the example it was written for. These are whole records copied from the two
/// APIs the package serves, and they are here because the last thing that went
/// wrong went wrong exactly this way — every individual rule worked, and the
/// record still carried a person's name into a public issue, because nobody had
/// run a whole record through and read the output.
///
/// Field names below come from the servers' own schemas:
/// bambuddy `backend/app/schemas/{print_queue,smart_plug}.py`, and LubeLogger's
/// vehicle/gas record as `lubelogger-mobile/lib/core/models/` models them.

/// What bambuddy passes to [LogRedactor], kept in step with
/// `bambuddy-mobile/lib/core/diagnostics/report_config.dart`.
///
/// Copied rather than imported: the package cannot depend on an application. A
/// drift here shows up as one of these tests describing a redactor bambuddy no
/// longer has, which is a cheaper failure than the alternative — the package
/// being tested only against rules invented to suit it.
LogRedactor bambuddyLike() => LogRedactor(
      ourKeys: {
        'id': RegExp(r'^\w+(\.\w+)*$'),
        'mat': RegExp(r'^[A-Z0-9]+(-[A-Z0-9]+)*$'),
        'event': RegExp(r'^[a-zA-Z]+$'),
        'reason': RegExp(r'^[a-zA-Z]+$'),
        'limit': RegExp(r'^[a-z]+$'),
      },
      secretKeyPatterns: [
        RegExp(
          r'(access_?code|serial'
          r'|(?:^|[^a-z0-9])entity|(?:^|[^a-z0-9])topic|headers'
          r'|rest_\w*(?:url|body))',
          caseSensitive: false,
        ),
      ],
      valuePatterns: [
        (RegExp(r'\bbb_[A-Za-z0-9_-]{8,}'), '[APIKEY]'),
        (
          RegExp(
            r'\b(?:0[0-3][A-Z][A-Z0-9]{9,13}|\d{2}[A-Z][0-9A-Z]{12})\b',
            caseSensitive: false,
          ),
          '[SERIAL]',
        ),
      ],
      freeTextKeys: const {
        'archive_name',
        'description',
        'file_name',
        'library_file_name',
        'location',
        'name',
        'notes',
        'printer_name',
        'target_location',
        'target_model',
      },
      schemaKeys: const {
        'locale',
        'mqtt_energy_path',
        'mqtt_power_path',
        'mqtt_state_path',
        'rest_power_path',
        'rest_status_path',
        'version',
      },
    );

/// What lubelogger passes, in the same spirit.
LogRedactor lubeloggerLike() => LogRedactor(
      ourKeys: {
        'id': RegExp(r'^\w+(\.\w+)*$'),
        'path': RegExp(r'^/[\w\-/.]*$'),
        'method': RegExp(r'^[A-Z]+$'),
      },
      secretKeyPatterns: [RegExp('email', caseSensitive: false)],
      freeTextKeys: const {
        'description',
        'identifier',
        'imagelocation',
        'licenseplate',
        'make',
        'model',
        'name',
        'notes',
        'tags',
        'value',
      },
      schemaKeys: const {'dateformat', 'currencysymbol'},
    );

void main() {
  group('bambuddy: an item off /api/v1/queue/', () {
    // The answer a live queue gives, with the fields a person fills in and the
    // fields the machine does. Trimmed to what a first record actually carries.
    final record = <String, Object?>{
      'id': 118,
      'position': 1,
      'status': 'printing',
      'printer_id': 3,
      'printer_name': 'Drukarka w sypialni Kasi',
      'archive_id': 91,
      'archive_name': 'Prezent_dla_Ani_v3.gcode.3mf',
      'library_file_id': null,
      'library_file_name': 'moje_modele/uchwyt_na_szczoteczki.3mf',
      'target_model': 'X1C',
      'target_location': 'Garaż u Piotrka',
      'required_filament_types': ['PLA', 'PETG'],
      'ams_mapping': [0, 1, 255],
      'use_ams': true,
      'flow_cali': 'auto',
      'quantity': 2,
      'scheduled_time': '2026-08-09T18:30:00',
      'printer_serial': '20P0AA000000001',
    };

    test('publishes the schema and measures every name a person chose', () {
      final out = bambuddyLike().scrubSample(record)! as Map;
      final text = jsonEncode(out);

      // What the record is read for: which fields came back, in what types, and
      // what the machine's own vocabulary says.
      expect(out['id'], 118);
      expect(out['status'], 'printing');
      expect(out['flow_cali'], 'auto');
      expect(out['use_ams'], true);
      expect(out['quantity'], 2);
      expect(out['ams_mapping'], [0, 1, 255]);
      expect(out['required_filament_types'], ['PLA', 'PETG']);
      expect(out['scheduled_time'], '2026-08-09T18:30:00');
      // A null is kept as a null: whether a field is set at all is often the
      // whole diagnosis, and measuring it would read as "set to something".
      expect(out['library_file_name'], isNot('<str:0>'));

      // And not one word of what the user typed.
      for (final leaked in ['Kasi', 'Ani', 'Piotrka', 'szczoteczki', 'moje_modele']) {
        expect(text, isNot(contains(leaked)), reason: '$leaked is the user\'s');
      }
      expect(out['printer_serial'], '[REDACTED]');
    });

    test('a name that looks like an enum is still a name', () {
      // The trap the free-text list exists for: one word of letters is the shape
      // of `printing` and of a printer somebody called `Sypialnia`. Shape alone
      // keeps the second, which is why the field name gets a vote.
      final out = bambuddyLike().scrubSample({
        'status': 'printing',
        'printer_name': 'Sypialnia',
        'target_location': 'Garaz',
      })! as Map;

      expect(out['status'], 'printing');
      expect(out['printer_name'], '<str:9>');
      expect(out['target_location'], '<str:5>');
    });

    test('a field the list has never heard of is caught by shape anyway', () {
      // A later server version adds a field nobody modelled. This is the case a
      // denylist can never win, and the reason the sample rule is an allowlist.
      final out = bambuddyLike().scrubSample({
        'gift_recipient_note': 'Dla Ani na urodziny',
        'batch_label': 'Prezenty świąteczne 2026',
      })! as Map;

      expect(out['gift_recipient_note'], '<str:19>');
      expect(out['batch_label'], '<str:24>');
    });
  });

  group('bambuddy: a plug off /api/v1/smart-plugs/', () {
    // Every field here is in the server's own schema; between them they describe
    // somebody's house, which is why so much of it is named as secret.
    final plug = <String, Object?>{
      'id': 4,
      'name': 'Gniazdko w garażu',
      'plug_type': 'homeassistant',
      'ip_address': '192.168.1.44',
      'username': 'morgan',
      'password': 'hunter2',
      'ha_entity_id': 'switch.szafa_biuro',
      'ha_power_entity': 'sensor.gniazdko_moc',
      'mqtt_topic': 'dom/parter/gniazdka/drukarka',
      'mqtt_power_topic': 'dom/parter/gniazdka/drukarka/moc',
      'mqtt_power_path': 'data.power',
      'mqtt_power_multiplier': 1.0,
      'mqtt_state_on_value': 'ON',
      'rest_on_url': 'http://plug.lan/cm?cmnd=Power%20On',
      'rest_on_body': '{"state":"on"}',
      'rest_headers': '{"Authorization":"Bearer eyJhbGciOiJIUzI1NiJ9.e.s"}',
      'rest_method': 'POST',
      'rest_status_path': 'state.power',
    };

    test('nothing that maps a home survives, and the wiring still reads', () {
      final out = bambuddyLike().scrubSample(plug)! as Map;
      final text = jsonEncode(out);

      // Everything that names a room, a broker tree or an endpoint on the LAN.
      for (final field in [
        'ha_entity_id',
        'ha_power_entity',
        'mqtt_topic',
        'mqtt_power_topic',
        'rest_on_url',
        'rest_on_body',
        'rest_headers',
        'username',
        'password',
      ]) {
        expect(out[field], '[REDACTED]', reason: '$field describes the house');
      }
      expect(text, isNot(contains('szafa_biuro')));
      expect(text, isNot(contains('dom/parter')));
      expect(text, isNot(contains('eyJhbGciOi')));

      // And what actually diagnoses a plug reporting nothing, which is the whole
      // reason this endpoint is sampled at all.
      expect(out['plug_type'], 'homeassistant');
      expect(out['rest_method'], 'POST');
      expect(out['mqtt_power_path'], 'data.power');
      expect(out['rest_status_path'], 'state.power');
      expect(out['mqtt_power_multiplier'], 1.0);
      expect(out['mqtt_state_on_value'], 'ON');
      // The plug's own name is the user's, and the IP is their network.
      expect(out['name'], '<str:17>');
      expect(out['ip_address'], isNot('192.168.1.44'));
    });

    test('the entity fence does not swallow a field merely containing it', () {
      // `(?:^|[^a-z0-9])entity` is fenced so `identity` stays readable. A rule
      // that ate it would blank a field that is nobody's secret.
      final out = bambuddyLike().scrubFields({'identity': 'local', 'n': 1});
      expect(out['identity'], 'local');
      expect(out['n'], 1);
    });
  });

  group('lubelogger: a vehicle and a fuel-up', () {
    final vehicle = <String, Object?>{
      'id': 12,
      'year': 2018,
      'make': 'Škoda',
      'model': 'Octavia',
      'licensePlate': 'WX 12345',
      'imageLocation': '/images/octavia_pod_domem.jpg',
      'tags': ['rodzinne', 'serwis u Marka'],
      'isElectric': false,
      'useHours': false,
      'identifier': 'TMBJJ7NE0J0123456',
      'extraFields': [
        {'name': 'Rozmiar opon', 'value': '205/55 R16'},
        {'name': 'Kod radia', 'value': '4417'},
      ],
    };

    test('the plate, the VIN and the photo path never leave the phone', () {
      final out = lubeloggerLike().scrubSample(vehicle)! as Map;
      final text = jsonEncode(out);

      expect(out['id'], 12);
      expect(out['year'], 2018);
      expect(out['isElectric'], false);
      // A plate is short and alphanumeric, which is why the shape rule refuses
      // "short alphanumeric" as a definition of technical.
      expect(out['licensePlate'], '<str:8>');
      expect(out['identifier'], '<str:17>');
      expect(out['make'], '<str:5>');
      expect(out['model'], '<str:7>');
      expect(out['imageLocation'], '<str:29>');
      expect(text, isNot(contains('WX 12345')));
      expect(text, isNot(contains('TMBJJ7NE')));
      expect(text, isNot(contains('octavia_pod_domem')));
      expect(text, isNot(contains('Marka')));
    });

    test('a schema the user extends at runtime is measured, keys and all', () {
      // `extraFields` is the one place the user invents the key as well as the
      // content — but the key arrives as the *value* of a fixed `name` field, so
      // both halves are the user's and both are measured.
      final out = lubeloggerLike().scrubSample(vehicle)! as Map;
      final extras = (out['extraFields']! as List).cast<Map>();

      expect(extras.first['name'], '<str:12>');
      expect(extras.first['value'], '<str:10>');
      // A radio code is a secret hiding in a field nobody would name as one.
      expect(extras.last['value'], '<str:4>');
    });

    test('only the head of a long list, because the tail repeats it', () {
      final out = lubeloggerLike().scrubSample({
        'tags': ['jeden', 'dwa', 'trzy', 'cztery', 'pięć'],
      })! as Map;

      expect((out['tags']! as List), hasLength(3));
    });

    test('the numbers and the dates a fuel-up is read for all survive', () {
      final record = <String, Object?>{
        'id': 903,
        'date': '01/15/2026',
        'odometer': 128450.5,
        'fuelConsumed': 41.2,
        'cost': 289.99,
        'isFillToFull': true,
        'missedFuelUp': false,
        'notes': 'Tankowanie po drodze do teściów',
        'tags': 'służbowe',
      };

      final out = lubeloggerLike().scrubSample(record)! as Map;

      // The single most common wire-format report is about exactly this: which
      // date format the server chose. Measuring it would answer `<str:10>`.
      expect(out['date'], '01/15/2026');
      expect(out['odometer'], 128450.5);
      expect(out['cost'], 289.99);
      expect(out['isFillToFull'], true);
      expect(out['notes'], '<str:31>');
      // One word, in a field the user writes into: the list is what saves it.
      expect(out['tags'], '<str:8>');
    });

    test('a server\'s own formatting is kept exactly as it sent it', () {
      // `MM/dd/yyyy` is not a date, not a number and not a word, so the shape
      // rule alone measures away the one thing the report was about.
      final r = lubeloggerLike();
      expect(r.scrubSample('MM/dd/yyyy', key: 'dateFormat'), 'MM/dd/yyyy');
      expect(r.scrubSample('zł', key: 'currencySymbol'), 'zł');
    });
  });

  group('what a user action leaves behind, end to end', () {
    test('a failed save is described without quoting what was saved', () {
      // The ordinary field pass, not the sample rule: this is a message, not a
      // record. What it must still catch is the host, the key and the token.
      final r = bambuddyLike()
        ..remember('bb_ab12cd34ef56', '[APIKEY]')
        ..rememberServerUrl('http://printer.lan:8080');

      final out = r.scrubFields({
        'method': 'POST',
        'path': '/api/v1/queue/',
        'status': 500,
        'msg': 'Failed host lookup: \'printer.lan\'',
        'headers': {'X-API-Key': 'bb_ab12cd34ef56'},
        'cover': 'http://printer.lan:8080/img/x.png?token=abc123',
      });

      expect(out['method'], 'POST');
      expect(out['path'], '/api/v1/queue/');
      expect(out['status'], 500);
      // A socket error is not a URL, so only the exact remembered host catches it.
      expect(out['msg'], "Failed host lookup: '[HOST]'");
      expect(out['headers'], '[REDACTED]');
      // Scheme and port survive — half the diagnosis — while the address and the
      // token do not.
      expect(out['cover'], 'http://[HOST]:8080/img/x.png?token=[REDACTED]');
    });

    test('a tap on a control keeps its identifier, whatever the server is called',
        () {
      // The demo server is `http://demo`, so `demo` is a remembered host — and
      // without the vocabulary rule every `setup.demo` in the log would read
      // `setup.[HOST]`.
      final r = bambuddyLike()..rememberServerUrl('http://demo');

      expect(r.scrubFields({'id': 'setup.demo'})['id'], 'setup.demo');
      expect(r.scrubFields({'id': 'archive.card'})['id'], 'archive.card');
      // The shape is the guard: an identifier built out of somebody's file name
      // is not the app's vocabulary and goes through the scrub after all.
      expect(
        r.scrubFields({'id': 'archive.card Prezent dla demo'})['id'],
        'archive.card Prezent dla [HOST]',
      );
    });

    test('a material named like the server survives at every depth', () {
      // The WebSocket probe reports an AMS slot's material as a nested `mat`,
      // and a server called `pla` would turn every loaded slot into `[HOST]`.
      final r = bambuddyLike()..rememberServerUrl('http://pla');

      final out = r.scrubFields({
        'ams': [
          {
            'id': 'ams.0',
            'trays': [
              {'mat': 'PLA', 'k': 0.02},
            ],
          },
        ],
      });

      final tray = (((out['ams']! as List).single as Map)['trays']! as List)
          .single as Map;
      expect(tray['mat'], 'PLA');
    });
  });

  group('shapes that must not be mistaken for one another', () {
    test('an HMS code is not a printer serial', () {
      // `030001000001000A` matched the serial pattern before it insisted on a
      // letter in the third position, and turning an HMS code into `[SERIAL]`
      // blinds the log to the one field the HMS catalog exists to read.
      final r = bambuddyLike();
      expect(r.scrubString('030001000001000A'), '030001000001000A');
      // Nor is a float.
      expect(r.scrubString('33.01666666666665'), '33.01666666666665');
      // A real one still goes.
      expect(r.scrubString('20P0AA000000001'), '[SERIAL]');
      expect(r.scrubString('00M09A123456789'), '[SERIAL]');
    });

    test('a firmware version is not an IP address', () {
      final r = bambuddyLike();
      expect(r.scrubString('01.09.01.00'), '01.09.01.00');
      expect(r.scrubString('192.168.1.44'), '[IP]');
    });

    test('a word containing a secret name is not a secret', () {
      final out = bambuddyLike().scrubFields({
        'monkey': 'kept',
        'keyboard': 'kept',
        'plug_type': 'tasmota',
        'rest_method': 'POST',
        'mqtt_state_path': 'state.power',
      });

      expect(out['monkey'], 'kept');
      expect(out['keyboard'], 'kept');
      // Named as deliberately NOT secret: which integration is in use is the
      // first thing to know, and a JSON pointer is a field name, not an address.
      expect(out['plug_type'], 'tasmota');
      expect(out['rest_method'], 'POST');
      expect(out['mqtt_state_path'], 'state.power');
    });
  });
}
