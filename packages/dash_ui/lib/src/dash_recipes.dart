import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dash_tokens.dart';

/// Categorical colours for a chart's series, in the order they are handed out.
/// Past the end a chart pools the rest in `textTertiary` rather than reusing a
/// colour, so two legend rows never share a dot.
const seriesPalette = [
  Color(0xFF22C55E),
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFA855F7),
  Color(0xFF14B8A6),
  Color(0xFFEC4899),
  Color(0xFF84CC16),
];

/// Decorations and colour sets built from the tokens, for the things every
/// screen draws the same way.
extension DashTokenRecipes on DashTokens {
  /// [count] colours that belong to this theme, to tell [count] things apart.
  /// The first is [accent] itself. The rest take hues the web app uses for its
  /// accents — green, teal, blue, indigo, purple, orange and amber, with red left
  /// to [danger], and pink as the eighth, which it uses rarely — at the accent's
  /// own saturation and lightness, so
  /// every one reads as the same family at the same weight in either brightness.
  /// Blue, orange and amber are the theme's own ([accentBlue], [accentOrange],
  /// [warning]) so they match the rest of the app. Fewer than eight are spread
  /// over the eight; past eight the hues repeat.
  List<Color> accentSeries(int count) {
    if (count <= 0) return const [];
    final base = HSLColor.fromColor(accent);
    double hueOf(Color c) => HSLColor.fromColor(c).hue;
    final hues = [
      base.hue,
      173.0,
      hueOf(accentBlue),
      240.0,
      271.0,
      330.0,
      hueOf(accentOrange),
      hueOf(warning),
    ];
    return [
      accent,
      for (var i = 1; i < count; i++)
        base
            .withHue(
              hues[(i * hues.length ~/ math.min(count, hues.length)) %
                  hues.length],
            )
            .toColor(),
    ];
  }

  /// The card every screen is built out of: gradient fill, 22 px
  /// corners, hairline border. Seventeen screens spelled it out before it had
  /// a name, which is why the two `SectionCard` classes looked like the same
  /// widget written twice — they are two headers over one box, and this is the
  /// box. A card that needs a different border writes its own.
  BoxDecoration get cardBox => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: cardBorder),
  );
}
