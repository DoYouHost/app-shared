import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// One choice in a grid of icons or colours: a [kMinInteractiveDimension] touch cell
/// with the drawing centred in it, so the target meets the guideline while the
/// drawing keeps its own size. The ink and the semantics node are the whole cell.
class PickerTile extends StatelessWidget {
  const PickerTile({
    super.key,
    required this.drawing,
    required this.onTap,
    required this.child,
    this.round = false,
  });

  /// The drawing's side, in dp.
  final double drawing;
  final VoidCallback onTap;

  /// Fills the [drawing] box it is given.
  final Widget child;
  final bool round;

  /// The `Wrap` gap that keeps the drawings where they were: [oldSpacing] between
  /// drawings of [drawing] dp, now that each sits in a cell of its own. Never
  /// negative; a drawing as wide as the cell leaves nothing to take back.
  static double gap(double drawing, double oldSpacing) =>
      math.max(0, drawing + oldSpacing - kMinInteractiveDimension);

  @override
  Widget build(BuildContext context) => InkWell(
    customBorder: round
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    onTap: onTap,
    child: SizedBox.square(
      dimension: kMinInteractiveDimension,
      child: Center(
        child: SizedBox.square(dimension: drawing, child: child),
      ),
    ),
  );
}
