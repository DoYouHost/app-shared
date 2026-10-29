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

/// The font weights: every `fontWeight` is one of these four, a step of 100 apart
/// at least. A weight in between (500, 550, 800) takes the nearest.
abstract final class DashWeight {
  /// Running text.
  static const FontWeight regular = FontWeight.w400;

  /// A quieter label, a second line.
  static const FontWeight medium = FontWeight.w500;

  /// A name, a value, a row's title.
  static const FontWeight semibold = FontWeight.w600;

  /// A heading, a number meant to be read across a room.
  static const FontWeight bold = FontWeight.w700;
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

/// The size of a box: a swatch, a thumbnail, a tile, a chart, a strip. One ladder
/// for every width, height, minimum and maximum, named by what it measures in dp.
///
/// The steps widen as they grow, so no two are close enough to mistake: 4 apart to
/// 24, 8 apart to 80, 16 to 128, then 32 or more. A size between two takes the
/// nearer, the larger on a tie. A touch target is `kMinInteractiveDimension`
/// (48, which is [d48]) and a gap is `DashSpace`, never one of these.
abstract final class DashSize {
  static const double d4 = 4;
  static const double d8 = 8;
  static const double d12 = 12;
  static const double d16 = 16;
  static const double d20 = 20;
  static const double d24 = 24;
  static const double d32 = 32;
  static const double d40 = 40;
  static const double d48 = 48;
  static const double d56 = 56;
  static const double d64 = 64;
  static const double d72 = 72;
  static const double d80 = 80;
  static const double d96 = 96;
  static const double d112 = 112;
  static const double d128 = 128;
  static const double d160 = 160;
  static const double d192 = 192;
  static const double d240 = 240;
  static const double d320 = 320;
}

/// Letter spacing: a heading drawn tight, a label a little open, an upper-case
/// caption wide, a spaced code (a PIN, a serial) wider still.
abstract final class DashTracking {
  static const double tight = -0.4;
  static const double label = 0.4;
  static const double caps = 1.2;
  static const double wide = 4;
}

/// The width of a line: a border or a stroked arc.
abstract final class DashStroke {
  /// A hairline border.
  static const double hairline = 1;

  /// A selected border, a gauge's arc.
  static const double regular = 2;

  /// A heavy ring.
  static const double heavy = 4;
}

/// The blur of a shadow.
abstract final class DashBlur {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
}

/// The elevation of a surface that floats above the screen: a menu, a sheet, a
/// dialog. A flat surface has none.
abstract final class DashElevation {
  static const double raised = 8;
}

/// From this text scale up a layout stops fitting its design and reflows: a
/// row becomes a column, a pill drops below its title, a list scrolls whole.
const double dashLargeTextScale = 1.3;

/// Whether the system text size is above [dashLargeTextScale].
bool dashLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > dashLargeTextScale;
