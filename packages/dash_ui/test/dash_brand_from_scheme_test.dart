import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

void main() {
  DashBrand fromSeed(Color seed) => DashBrand.fromSchemes(
    light: ColorScheme.fromSeed(seedColor: seed),
    dark: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
  );

  Color seedOf(int hue, double saturation) =>
      HSLColor.fromAHSL(1, hue.toDouble(), saturation, 0.5).toColor();

  bool isGrey(Color c) => c.r == c.g && c.g == c.b;

  test('every seeded brand passes the audit', () {
    for (var hue = 0; hue < 360; hue += 15) {
      for (final saturation in [0.0, 0.1, 0.3, 0.6, 1.0]) {
        final brand = fromSeed(seedOf(hue, saturation));
        expect(
          dashContrastAudit(brand),
          isEmpty,
          reason: 'hue $hue, saturation $saturation',
        );
      }
    }
  });

  // fromSeed lifts every primary to a chroma of about 36; a system palette or
  // a monochrome scheme can hand over far less.
  group('a primary of low chroma', () {
    DashBrand withPrimaryChroma(int hue, double chroma) {
      ColorScheme scheme(Brightness b) => ColorScheme.fromSeed(
        seedColor: seedOf(hue, 0.6),
        brightness: b,
      ).copyWith(primary: Color(Hct.from(hue.toDouble(), chroma, 40).toInt()));
      return DashBrand.fromSchemes(
        light: scheme(Brightness.light),
        dark: scheme(Brightness.dark),
      );
    }

    test('passes the audit at every chroma', () {
      for (var hue = 0; hue < 360; hue += 45) {
        for (final chroma in [0.0, 2, 4, 8, 12, 16, 24]) {
          expect(
            dashContrastAudit(withPrimaryChroma(hue, chroma.toDouble())),
            isEmpty,
            reason: 'hue $hue, chroma $chroma',
          );
        }
      }
    });

    test('chroma 0 is an exact grey', () {
      final brand = withPrimaryChroma(200, 0);
      for (final c in [
        brand.dark.fill,
        brand.dark.ink,
        brand.light.fill,
        brand.light.ink,
      ]) {
        expect(isGrey(c), isTrue, reason: '$c');
      }
    });

    // A pastel wallpaper keeps its tint rather than turning grey.
    test('chroma 12 keeps its hue', () {
      final brand = withPrimaryChroma(200, 12);
      expect(isGrey(brand.light.fill), isFalse);
      expect(Hct.fromInt(brand.light.fill.toARGB32()).hue, closeTo(200, 10));
    });
  });

  // Why the dark glow is surfaceContainerLow: the first draft took
  // surfaceContainerHigh, and the fixed muted inks, which no brand can nudge,
  // fell under 4.5:1 on it.
  test('a brighter dark glow fails the audit', () {
    final failing = <int>[];
    for (var hue = 0; hue < 360; hue += 15) {
      final seed = seedOf(hue, 0.6);
      final dark = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      );
      final brand = fromSeed(seed);
      final s = brand.darkSurfaces;
      final brighter = DashBrand(
        dark: brand.dark,
        light: brand.light,
        onAccent: brand.onAccent,
        lightSurfaces: brand.lightSurfaces,
        darkSurfaces: DashSurfaces(
          glow: dark.surfaceContainerHigh,
          middle: s.middle,
          edge: s.edge,
          cardEnd: s.cardEnd,
          overlay: s.overlay,
          scaffold: s.scaffold,
        ),
      );
      if (dashContrastAudit(brighter).isNotEmpty) failing.add(hue);
    }
    expect(failing, hasLength(24));
  });

  test('two brands built from the same schemes are equal', () {
    final a = fromSeed(const Color(0xFF2E7DD7));
    final b = fromSeed(const Color(0xFF2E7DD7));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(fromSeed(const Color(0xFFD72E7D))));
  });
}
