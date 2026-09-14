import 'package:flutter/widgets.dart';

/// Centres [child] and caps its width, so a column of rows stays readable on a
/// tablet or in landscape. A null [maxWidth] leaves the child as it is, for an
/// application that has not chosen a cap.
class MaxContentWidth extends StatelessWidget {
  const MaxContentWidth({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double? maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth;
    if (width == null) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}
