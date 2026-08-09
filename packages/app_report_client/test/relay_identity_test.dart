import 'package:app_report_client/app_report_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The installation id, which is the only thing the relay meters by.
///
/// Two properties matter and they pull against each other: it has to be stable,
/// or every report looks like a first report and the escalating wait never
/// escalates; and it has to be *only* an id, or a value meant for rate limiting
/// becomes a way to recognise somebody.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('the same installation answers the same id every time', () async {
    final first = await installId(prefs);
    final second = await installId(prefs);
    final third = await installId(prefs);

    expect(second, first);
    expect(third, first);
  });

  test('it outlives the process, because the wait has to', () async {
    final first = await installId(prefs);

    // Re-read from storage, as the next launch does.
    final reopened = await SharedPreferences.getInstance();

    expect(await installId(reopened), first);
  });

  test('it is a v4 UUID, and nothing about the device', () async {
    final id = await installId(prefs);

    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('two installations do not collide', () async {
    final mine = await installId(prefs);

    // A second install, i.e. empty storage.
    SharedPreferences.setMockInitialValues({});
    final theirs = await installId(await SharedPreferences.getInstance());

    expect(theirs, isNot(mine));
  });

  test('reinstalling is what rotating it means', () async {
    // The honest bound on what this can be used for: it is not derived from
    // anything on the device, so clearing storage really does start over.
    final before = await installId(prefs);
    await prefs.clear();

    expect(await installId(prefs), isNot(before));
  });

  test('an id already stored is used as it stands, not regenerated', () async {
    // Whatever an older build wrote is the identity the relay has been counting
    // against; replacing it would reset somebody's escalating wait to zero.
    SharedPreferences.setMockInitialValues({
      'diagnostics.installId': 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa',
    });

    expect(
      await installId(await SharedPreferences.getInstance()),
      'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa',
    );
  });
}
