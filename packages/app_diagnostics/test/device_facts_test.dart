import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:flutter/widgets.dart' show Brightness, Size;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _WoundStopwatch elapsed;

  setUp(() {
    // A fresh one per stamp, as `Stopwatch.new` would hand over.
    AppStart.newStopwatch = () => elapsed = _WoundStopwatch();
  });

  tearDown(() {
    AppStart.at = null;
    AppStart.newStopwatch = Stopwatch.new;
  });

  test('uptime is null until main stamps the start', () {
    expect(AppStart.uptimeSeconds, isNull);

    AppStart.at = DateTime.now();
    elapsed.wind(const Duration(minutes: 3));

    expect(AppStart.uptimeSeconds, 180);
  });

  test('the clock is monotonic, so moving the system one does not count', () {
    // The whole reason it is a stopwatch: an NTP correction of two hours would
    // otherwise report an app opened a minute ago as having run all morning.
    AppStart.at = DateTime.now();
    elapsed.wind(const Duration(seconds: 60));
    AppStart.at = DateTime.now().subtract(const Duration(hours: 2));

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

/// A [Stopwatch] the test winds by hand.
class _WoundStopwatch implements Stopwatch {
  Duration _elapsed = Duration.zero;
  bool _running = false;

  void wind(Duration by) => _elapsed += by;

  @override
  Duration get elapsed => _elapsed;

  @override
  void start() => _running = true;

  @override
  void stop() => _running = false;

  @override
  void reset() => _elapsed = Duration.zero;

  @override
  bool get isRunning => _running;

  @override
  int get elapsedTicks => _elapsed.inMicroseconds;

  @override
  int get elapsedMicroseconds => _elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => _elapsed.inMilliseconds;

  @override
  int get frequency => Duration.microsecondsPerSecond;
}
