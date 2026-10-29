import 'package:dash_ui/dash_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brands.dart';

void main() {
  Future<DashTokens> tokensUnder(WidgetTester tester, ThemeData theme) async {
    late DashTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            tokens = DashTokens.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return tokens;
  }

  testWidgets('of() finds the brand the theme was built with', (tester) async {
    final tokens = await tokensUnder(
      tester,
      buildDashThemeData(Brightness.light, brand: gold),
    );

    expect(tokens, const DashTokens.light(gold));
    expect(tokens.accentInk, gold.light.ink);
  });

  // A widget test's bare MaterialApp registers no tokens. The fallback must not
  // be either application's brand, or a test in one app would pass on the
  // other's accent.
  testWidgets('under a plain theme, the accent is the colour scheme\'s', (
    tester,
  ) async {
    final theme = ThemeData(brightness: Brightness.dark);
    final tokens = await tokensUnder(tester, theme);

    expect(tokens.brightness, Brightness.dark);
    expect(tokens.accent, theme.colorScheme.primary);
    expect(tokens.onAccent, theme.colorScheme.onPrimary);
    expect(tokens.textPrimary, DashTokens.dark(green).textPrimary);
  });

  test('the accent follows brightness, the rest of the palette does not '
      'depend on the brand', () {
    const darkGreen = DashTokens.dark(green);
    const darkGold = DashTokens.dark(gold);

    expect(darkGreen.accent, green.dark.fill);
    expect(const DashTokens.light(green).accent, green.light.fill);
    expect(darkGold.textSecondary, darkGreen.textSecondary);
    expect(darkGold.overlaySurface, darkGreen.overlaySurface);
    expect(darkGold, isNot(darkGreen));
  });

  // ThemeData.lerp flips brightness at the midpoint; tokens have to flip with
  // it rather than report a blend of two palettes.
  test('lerp snaps at the midpoint', () {
    const from = DashTokens.light(green);
    const to = DashTokens.dark(green);

    expect(from.lerp(to, 0.49), from);
    expect(from.lerp(to, 0.5), to);
    expect(from.lerp(null, 1), from);
  });

  // A surface change must rebuild the theme, so it has to break equality.
  test('brand equality includes the surfaces', () {
    const tinted = DashBrand(
      dark: DashAccent(fill: Color(0xFF5FE08A), ink: Color(0xFF5FE08A)),
      light: DashAccent(fill: Color(0xFF34C46E), ink: Color(0xFF18733D)),
      onAccent: Color(0xFF0A0C08),
      darkSurfaces: DashSurfaces(
        glow: Color(0xFF101418),
        middle: Color(0xFF07090A),
        edge: Color(0xFF050605),
        cardEnd: Color(0x04FFFFFF),
        overlay: Color(0xFF0E1310),
        scaffold: Color(0xFF07090A),
      ),
    );

    expect(green.darkSurfaces, DashSurfaces.classicDark);
    expect(green.lightSurfaces, DashSurfaces.classicLight);
    expect(tinted, isNot(green));
    expect(tinted.hashCode, isNot(green.hashCode));
    expect(
      DashBrand(dark: green.dark, light: green.light, onAccent: green.onAccent),
      green,
    );
  });

  // The constants the tokens held before brands carried surfaces; a brand that
  // names none must paint exactly these, or every existing app shifts.
  test('a brand without surfaces paints the classic grounds', () {
    const dark = DashTokens.dark(green);
    const light = DashTokens.light(green);

    expect(
      dark.backgroundGradient,
      const RadialGradient(
        center: Alignment(-0.6, -1),
        radius: 1.4,
        colors: [Color(0xFF131A12), Color(0xFF07090A), Color(0xFF050605)],
        stops: [0.0, 0.55, 1.0],
      ),
    );
    expect(
      dark.cardGradient,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x0DFFFFFF), Color(0x04FFFFFF)],
      ),
    );
    expect(dark.overlaySurface, const Color(0xFF0E1310));
    expect(dark.scaffold, const Color(0xFF07090A));

    expect(
      light.backgroundGradient,
      const RadialGradient(
        center: Alignment(-0.6, -1),
        radius: 1.4,
        colors: [Color(0xFFEAF2E7), Color(0xFFF6F8F4), Color(0xFFFDFEFC)],
        stops: [0.0, 0.55, 1.0],
      ),
    );
    expect(
      light.cardGradient,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF5F7F3)],
      ),
    );
    expect(light.overlaySurface, const Color(0xFFF6F8F4));
    expect(light.scaffold, const Color(0xFFFDFEFC));
  });

  test('custom surfaces change the grounds and nothing else', () {
    const surfaces = DashSurfaces(
      glow: Color(0xFF111111),
      middle: Color(0xFF222222),
      edge: Color(0xFF333333),
      cardEnd: Color(0xFF444444),
      overlay: Color(0xFF555555),
      scaffold: Color(0xFF666666),
    );
    final brand = DashBrand(
      dark: green.dark,
      light: green.light,
      onAccent: green.onAccent,
      darkSurfaces: surfaces,
    );
    final t = DashTokens.dark(brand);
    const classic = DashTokens.dark(green);

    expect((t.backgroundGradient as RadialGradient).colors, [
      surfaces.glow,
      surfaces.middle,
      surfaces.edge,
    ]);
    expect(t.cardGradient.colors, [const Color(0x0DFFFFFF), surfaces.cardEnd]);
    expect(t.overlaySurface, surfaces.overlay);
    expect(t.scaffold, surfaces.scaffold);
    expect(t.overlayBorder, classic.overlayBorder);
    expect(t.textTertiary, classic.textTertiary);
    expect(t.accent, classic.accent);
    expect(
      DashTokens.light(brand).backgroundGradient,
      const DashTokens.light(green).backgroundGradient,
    );
    expect(t, isNot(classic));
    expect(t.lerp(classic, 0.5), classic);
  });

  test('copyWith re-resolves the palette', () {
    final dark = const DashTokens.light(
      green,
    ).copyWith(brightness: Brightness.dark);

    expect(dark, const DashTokens.dark(green));
    expect(dark.textPrimary, const DashTokens.dark(gold).textPrimary);
  });
}
