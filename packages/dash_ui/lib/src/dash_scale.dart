import 'package:flutter/widgets.dart';

/// The icon sizes: every `Icon(size:)` and `iconSize` is one of these.
///
/// A 4 dp grid like [DashSpace], with no two steps closer than 4 dp. The app
/// had icons at 12, 13, 14, 15, 16, 18, 19, 20, 22, 24 and 26 dp side by side,
/// which no one could tell apart and no rule could hold.
abstract final class DashIcon {
  /// Inside a pill, a counter or a one-line caption.
  static const double xs = 12;

  /// Beside body text.
  static const double sm = 16;

  /// The standard action or row icon.
  static const double md = 20;

  /// A toolbar or a tile's lead icon.
  static const double lg = 24;

  /// A hero glyph in an empty state or a big control.
  static const double xl = 32;

  /// The glyph of a full-screen empty or error state.
  static const double xxl = 48;
}

/// The corner radii of surfaces and controls, on the same 4 dp grid.
abstract final class DashRadius {
  /// A thumb, a bar's end, a tag.
  static const double xs = 4;

  /// A small chip, a swatch, a menu row.
  static const double sm = 8;

  /// A field, a button, a tile.
  static const double md = 12;

  /// A card.
  static const double lg = 16;

  /// A sheet, a banner, a dialog.
  static const double xl = 20;

  /// Fully round, whatever the height: a capsule, a dot.
  static const double pill = 999;
}

/// The alpha an ink or an accent takes when it is a wash, an outline or a scrim:
/// eight steps, named for the job, so two screens that mean the same thing cannot
/// drift to 0.16 and 0.18. A value in between takes the nearest.
abstract final class DashAlpha {
  /// A hover, a splash or a track: barely there.
  static const double faint = 0.08;

  /// The fill of a selected or tinted surface: an accent over the card.
  static const double wash = 0.14;

  /// A disabled ink, a muted outline, a divider on a picture.
  static const double soft = 0.32;

  /// The outline of a washed surface.
  static const double outline = 0.4;

  /// What dims the screen behind a dialog or a floating control.
  static const double scrim = 0.5;

  /// A secondary ink over a picture or over an accent.
  static const double strong = 0.7;

  /// A surface that is almost opaque but lets the ground show.
  static const double heavy = 0.85;

  /// A surface laid over a picture that must still read: a badge on a camera
  /// image, a bar over a canvas.
  static const double cover = 0.95;
}

/// The font sizes of the type scale ([DashTokens]'s text styles are built from
/// these); a `fontSize:` anywhere else is one of these too.
abstract final class DashFontSize {
  static const double micro = 11;
  static const double label = 12;
  static const double body = 13;
  static const double title = 14;
  static const double lead = 16;
  static const double heading = 18;
  static const double display = 20;
  static const double hero = 26;

  /// A reading read across a room: a temperature, a percentage.
  static const double numeral = 40;
}

/// The heights of a linear progress bar: a hairline in a list row, a thick bar
/// on a card.
abstract final class DashBar {
  static const double thin = 4;
  static const double thick = 8;
}

/// Line heights (a multiple of the font size) for text that must hold a fixed
/// number of lines.
abstract final class DashLeading {
  /// Two lines of a hint that sit tighter than the font's own spacing.
  static const double snug = 1.25;
}

/// Letter spacing, for the one place the scale allows it: an upper-case label.
abstract final class DashTracking {
  static const double label = 0.3;
}

/// From this text scale up a layout stops fitting its design and reflows: a
/// row becomes a column, a pill drops below its title, a list scrolls whole.
const double dashLargeTextScale = 1.3;

/// Whether the system text size is above [dashLargeTextScale].
bool dashLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > dashLargeTextScale;
