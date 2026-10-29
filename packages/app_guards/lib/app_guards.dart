/// Source scans that hold an application to the Dash standards.
///
/// Each scan returns its offenders as `path:line  what` strings and asserts
/// nothing itself, so an application's test reads
/// `expect(rawSpacing(), isEmpty, reason: …)` and keeps its own wording and its
/// own exceptions. Paths are relative to the working directory, which under
/// `flutter test` is the application's root.
library;

export 'src/finder_copy.dart';
export 'src/short_words.dart';
export 'src/sizes.dart';
export 'src/source_files.dart' show dartFiles;
export 'src/spacing.dart';
export 'src/wrap_run_spacing.dart';
