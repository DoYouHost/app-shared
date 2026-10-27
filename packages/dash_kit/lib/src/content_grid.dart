import 'package:dash_ui/dash_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Tiles in columns, each row as tall as its tallest tile.
///
/// A `GridView` with a `childAspectRatio` fixes the tile's height from its width,
/// so a tile whose text grows with the text scale (or with a longer translation)
/// overflows instead of growing. Here the height comes from the content: every
/// row is an [IntrinsicHeight] `Row` whose tiles stretch to the tallest one, so a
/// tile that draws its own background fills the row evenly.
///
/// The number of columns follows [minTileWidth], as many as fit, and never more
/// than [maxColumns]: a pair of buttons asks for two so that a lone one is not
/// left in half a row. Pass it scaled
/// by the text scale when the tile is text, so a larger font gets fewer, wider
/// tiles instead of a cut label. A last row with fewer tiles leaves its gaps empty.
///
/// A tile must not be vertically unbounded (no `Expanded` or `ListView` in its
/// column): it is measured for its intrinsic height. Tiles that are lists of their
/// own, or a hundred of them, belong in a lazy list.
class ContentGrid extends StatelessWidget {
  const ContentGrid({
    super.key,
    required this.minTileWidth,
    required this.children,
    this.spacing = DashSpace.sm,
    this.runSpacing = DashSpace.sm,
    this.maxColumns,
  }) : assert(minTileWidth > 0),
       assert(maxColumns == null || maxColumns > 0);

  /// The narrowest a tile may be before a column is dropped.
  final double minTileWidth;
  final double spacing;
  final double runSpacing;

  /// An upper bound on the columns, e.g. the number of tiles when they should
  /// share the width evenly instead of leaving room for more.
  final int? maxColumns;
  final List<Widget> children;

  /// How many columns of at least [minTileWidth] fit in [width], at least one.
  static int columnsFor(
    double width, {
    required double minTileWidth,
    double spacing = DashSpace.sm,
    int? maxColumns,
  }) => ((width + spacing) / (minTileWidth + spacing)).floor().clamp(
    1,
    maxColumns ?? 1 << 20,
  );

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(
          constraints.maxWidth,
          minTileWidth: minTileWidth,
          spacing: spacing,
          maxColumns: maxColumns,
        );
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) SizedBox(width: spacing),
                    Expanded(
                      child: start + i < children.length
                          ? children[start + i]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
