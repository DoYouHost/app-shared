import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// A clock the test moves by hand, handed to the body of [testWithClock].
class TestClock {
  TestClock(this.now);

  DateTime now;

  void tick(Duration by) => now = now.add(by);
}

/// A test whose body runs on a clock it controls, starting at [start]; move it
/// with [TestClock.tick].
void testWithClock(
  String description,
  DateTime start,
  dynamic Function(TestClock time) body,
) => test(description, () {
  final time = TestClock(start);
  return withClock(Clock(() => time.now), () => body(time));
});
