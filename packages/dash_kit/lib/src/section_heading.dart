import 'package:flutter/widgets.dart';

/// The words that name a section, marked as a heading for a screen reader, so
/// "jump to next heading" lands on it.
///
/// Only the words go inside. A control beside the title — a count, a
/// "Select all" — stays outside: merged into a heading it stops reading as the
/// button it is. Screen titles need none of this; `AppBar` marks its own.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(text, style: style));
}
