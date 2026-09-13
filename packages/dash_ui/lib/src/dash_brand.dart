import 'package:flutter/material.dart';

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

/// What an application brings to the design system: its accent in each theme,
/// and the ink painted on a solid accent fill.
///
/// Check a new brand with [dashContrastAudit] from the application's tests.
@immutable
class DashBrand {
  const DashBrand({
    required this.dark,
    required this.light,
    required this.onAccent,
  });

  /// The accent of a theme that was not built by `buildDashThemeData` — a
  /// widget test's bare `MaterialApp`. Taken from its colour scheme rather than
  /// from any one application, so the fallback never paints one app's brand
  /// into another.
  factory DashBrand.fromScheme(ColorScheme scheme) {
    final accent = DashAccent(fill: scheme.primary, ink: scheme.primary);
    return DashBrand(dark: accent, light: accent, onAccent: scheme.onPrimary);
  }

  final DashAccent dark;
  final DashAccent light;

  /// A single value because the fill it sits on is a constant swatch in both
  /// themes; a brand whose light fill differs enough to need another ink fails
  /// the audit rather than getting a second field.
  final Color onAccent;

  DashAccent of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  bool operator ==(Object other) =>
      other is DashBrand &&
      other.dark == dark &&
      other.light == light &&
      other.onAccent == onAccent;

  @override
  int get hashCode => Object.hash(dark, light, onAccent);
}
