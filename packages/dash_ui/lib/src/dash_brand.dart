import 'package:material_ui/material_ui.dart';

import 'dash_contrast.dart';

/// One theme's brand accent: the vivid [fill] and the [ink] used where the
/// accent is text or an icon.
///
/// They are two values because a vivid swatch that reads as a fill is too pale
/// to read as a word on a light card; the ink is the same hue, darkened until it
/// clears 4.5:1. On a dark ground the vivid swatch already does, and both are
/// usually the same colour.
@immutable
class DashAccent {
  const DashAccent({required this.fill, required this.ink});

  final Color fill;
  final Color ink;

  @override
  bool operator ==(Object other) =>
      other is DashAccent && other.fill == fill && other.ink == ink;

  @override
  int get hashCode => Object.hash(fill, ink);
}

/// One theme's grounds: the opaque backdrop gradient, the far end of a card
/// (a translucent wash in every dark theme this package builds), the overlay
/// behind dialogs and sheets, and the scaffold.
///
/// Three named stops rather than a list, so `==` compares values and an
/// instance can be `const`.
@immutable
class DashSurfaces {
  const DashSurfaces({
    required this.glow,
    required this.middle,
    required this.edge,
    required this.cardEnd,
    required this.overlay,
    required this.scaffold,
  });

  /// The green-tinted grounds every app had before brands could carry their
  /// own.
  static const classicDark = DashSurfaces(
    glow: Color(0xFF131A12),
    middle: Color(0xFF07090A),
    edge: Color(0xFF050605),
    cardEnd: Color(0x04FFFFFF),
    overlay: Color(0xFF0E1310),
    scaffold: Color(0xFF07090A),
  );

  static const classicLight = DashSurfaces(
    glow: Color(0xFFEAF2E7),
    middle: Color(0xFFF6F8F4),
    edge: Color(0xFFFDFEFC),
    cardEnd: Color(0xFFF5F7F3),
    overlay: Color(0xFFF6F8F4),
    scaffold: Color(0xFFFDFEFC),
  );

  /// The backdrop's stops, from the lit corner outwards.
  final Color glow;
  final Color middle;
  final Color edge;

  /// Where the card gradient ends; it starts at the theme's fixed white wash.
  final Color cardEnd;

  final Color overlay;
  final Color scaffold;

  @override
  bool operator ==(Object other) =>
      other is DashSurfaces &&
      other.glow == glow &&
      other.middle == middle &&
      other.edge == edge &&
      other.cardEnd == cardEnd &&
      other.overlay == overlay &&
      other.scaffold == scaffold;

  @override
  int get hashCode =>
      Object.hash(glow, middle, edge, cardEnd, overlay, scaffold);
}

/// What an application brings to the design system: its accent in each theme,
/// the ink painted on a solid accent fill, and optionally its own grounds.
///
/// Check a new brand with [dashContrastAudit] from the application's tests.
@immutable
class DashBrand {
  const DashBrand({
    required this.dark,
    required this.light,
    required this.onAccent,
    this.darkSurfaces = DashSurfaces.classicDark,
    this.lightSurfaces = DashSurfaces.classicLight,
  });

  /// The accent of a theme that was not built by `buildDashThemeData` — a
  /// widget test's bare `MaterialApp`. Taken from its colour scheme rather than
  /// from any one application, so the fallback never paints one app's brand
  /// into another.
  factory DashBrand.fromScheme(ColorScheme scheme) {
    final accent = DashAccent(fill: scheme.primary, ink: scheme.primary);
    return DashBrand(dark: accent, light: accent, onAccent: scheme.onPrimary);
  }

  /// A brand generated from a Material scheme pair — the system's dynamic
  /// colours, or `ColorScheme.fromSeed` for a preset — accent and grounds
  /// alike, built to pass [dashContrastAudit].
  factory DashBrand.fromSchemes({
    required ColorScheme light,
    required ColorScheme dark,
  }) => brandFromSchemes(light: light, dark: dark);

  final DashAccent dark;
  final DashAccent light;

  /// A single value because the fill it sits on is a constant swatch in both
  /// themes; a brand whose light fill differs enough to need another ink fails
  /// the audit rather than getting a second field.
  final Color onAccent;

  final DashSurfaces darkSurfaces;
  final DashSurfaces lightSurfaces;

  DashAccent of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  DashSurfaces surfacesOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaces : lightSurfaces;

  @override
  bool operator ==(Object other) =>
      other is DashBrand &&
      other.dark == dark &&
      other.light == light &&
      other.onAccent == onAccent &&
      other.darkSurfaces == darkSurfaces &&
      other.lightSurfaces == lightSurfaces;

  @override
  int get hashCode =>
      Object.hash(dark, light, onAccent, darkSurfaces, lightSurfaces);
}
