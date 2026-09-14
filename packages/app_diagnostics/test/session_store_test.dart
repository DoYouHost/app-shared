import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferencesSessionStore> store([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferencesSessionStore(await SharedPreferences.getInstance());
  }

  test('what was saved is what the next isolate reads', () async {
    final sessions = await store();
    expect(sessions.loadSession(), isNull);

    await sessions.saveSession('2026-09-14T10-00-00');

    expect(sessions.loadSession(), '2026-09-14T10-00-00');
  });

  test('null clears it, which is what stopping a recording does', () async {
    final sessions = await store({'diagnostics_session': 'old'});

    await sessions.saveSession(null);

    expect(sessions.loadSession(), isNull);
  });

  test('an empty id left by an older version reads as no session', () async {
    final sessions = await store({'diagnostics_session': ''});

    expect(sessions.loadSession(), isNull);
  });

  test('the key is the one both applications already shipped', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SharedPreferencesSessionStore(prefs).saveSession('id');

    expect(prefs.getString('diagnostics_session'), 'id');
  });
}
