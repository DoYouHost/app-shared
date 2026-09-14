import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter/widgets.dart' show Brightness, Size;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppStart.at = null);

  test('uptime is null until main stamps the start', () {
    expect(AppStart.uptimeSeconds, isNull);

    AppStart.at = DateTime.now().subtract(const Duration(minutes: 3));
    expect(AppStart.uptimeSeconds, closeTo(180, 2));
  });

  test('a clock moved backwards reads as zero, never as negative', () {
    AppStart.at = DateTime.now().add(const Duration(minutes: 5));

    expect(AppStart.uptimeSeconds, 0);
  });

  testWidgets('the header carries the screen, the offset and the uptime', (
    tester,
  ) async {
    AppStart.at = DateTime.now();
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);

    final facts = await deviceEnvironment();

    expect(facts['screen'], '360x800@3.00');
    // `+02:00`, the notation a reader already knows from a timestamp.
    expect(facts['tz'], matches(RegExp(r'^[+-]\d{2}:\d{2}$')));
    expect(facts['uptime_s'], isNotNull);
    // Only when they are not the default, so a header stays short.
    expect(facts.containsKey('text_scale'), isFalse);
    expect(facts.containsKey('dark'), isFalse);
  });

  testWidgets('without a stamped start there is no uptime to report', (
    tester,
  ) async {
    final facts = await deviceEnvironment();

    expect(facts.containsKey('uptime_s'), isFalse);
    expect(facts['tz'], isNotNull);
  });

  testWidgets('a text scale and dark mode appear once they are set', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 1440);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });

    final facts = await deviceEnvironment();

    expect(facts['text_scale'], 1.3);
    expect(facts['dark'], isTrue);
  });
}
