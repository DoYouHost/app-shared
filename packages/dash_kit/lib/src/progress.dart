import 'package:flutter/material.dart';

/// What a screen shows while it has nothing else: the spinner, centred.
class DashLoading extends StatelessWidget {
  const DashLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// The spinner that stands in for an icon or a label while one action runs.
///
/// [size] is the slot it replaces, so the row does not reflow when it appears;
/// the stroke stays thin at every size, or it reads as a second icon. [color]
/// is for a spinner on an accent fill. [value] fills the ring when the work
/// knows how far along it is; null keeps it turning.
class DashSpinner extends StatelessWidget {
  const DashSpinner({super.key, this.size = 18, this.color, this.value});

  final double size;
  final Color? color;
  final double? value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: color,
      value: value,
    ),
  );
}
