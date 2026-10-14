/// The test harness pieces both applications need the same way.
///
/// Each one exists because a test went green for the wrong reason, or red with
/// an error that hid the real one: a mock handler that counts its own
/// declaration, a body matched by subset, a tap below the fold of an 800×600
/// window. Take it as a `dev_dependency`.
library;

export 'src/clock.dart';
export 'src/fakes.dart';
export 'src/fixtures.dart';
export 'src/requests.dart';
export 'src/temp_dir.dart';
export 'src/widgets.dart';
