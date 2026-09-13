import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';
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

  test('copyWith re-resolves the palette', () {
    final dark = const DashTokens.light(
      green,
    ).copyWith(brightness: Brightness.dark);

    expect(dark, const DashTokens.dark(green));
    expect(dark.textPrimary, const DashTokens.dark(gold).textPrimary);
  });
}
