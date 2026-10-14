import 'package:app_guards/app_guards.dart';

/// `dart run app_guards:glue_short_words [l10n dir]` — glues every one-letter
/// word in the `.arb` files (default `lib/l10n`). Run `flutter gen-l10n` after.
// A command-line tool: its output is the report.
// ignore_for_file: avoid_print

void main(List<String> args) {
  final dir = args.isEmpty ? 'lib/l10n' : args.first;
  glueArbFiles(l10nDir: dir).forEach((path, n) => print('$path: $n strings'));
}
