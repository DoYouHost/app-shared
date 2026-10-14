import 'dart:io';
import 'dart:isolate';

/// Runs a script that ships in this package's `tool/` directory with
/// [interpreter], in the caller's working directory, passing [args] through and
/// the terminal with them. Returns the script's exit code.
///
/// The scripts stay what they were in the applications (Python, POSIX sh): one
/// copy here is the whole point, and porting them would have been a second
/// implementation to keep in step with the first.
Future<int> runBundled(
  String interpreter,
  String script,
  List<String> args,
) async {
  // Unsupported under `flutter test`, which is why [runScript] is apart.
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:app_guards/app_guards.dart'),
  );
  if (library == null) {
    stderr.writeln('app_guards: cannot find its own package directory');
    return 2;
  }
  return runScript(
    interpreter,
    library.resolve('../tool/$script').toFilePath(),
    args,
  );
}

/// Runs [path] with [interpreter] in the working directory, the terminal
/// passed through; the script's exit code.
Future<int> runScript(
  String interpreter,
  String path,
  List<String> args,
) async {
  final process = await Process.start(interpreter, [
    path,
    ...args,
  ], mode: ProcessStartMode.inheritStdio);
  return process.exitCode;
}
