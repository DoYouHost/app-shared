import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brands.dart';

void main() {
  DashBrand withLightInk(DashBrand brand, Color ink) => DashBrand(
    dark: brand.dark,
    light: DashAccent(fill: brand.light.fill, ink: ink),
    onAccent: brand.onAccent,
  );

  test('both brands pass in both themes', () {
    expect(dashContrastAudit(green), isEmpty);
    expect(dashContrastAudit(gold), isEmpty);
  });

  // The gold ink lubelogger shipped before this package: 3.81:1 against the
  // light background corner, a button label nobody with low vision could read.
  test('an ink that is too pale for small text fails, naming where', () {
    final issues = dashContrastAudit(
      withLightInk(gold, const Color(0xFF9A6E12)),
    );

    // The background's first stop under a sub-card: the harshest ground for a
    // dark ink, not the white card that flatters it.
    expect(issues, const [
      DashContrastIssue(
        Brightness.light,
        'accentInk',
        'is 3.81:1 over #e5ede2',
      ),
    ]);
  });

  test('an ink dark enough but of another hue fails', () {
    // Clears 4.5:1 comfortably, and reads as brown-red rather than amber.
    final issues = dashContrastAudit(
      withLightInk(gold, const Color(0xFF7A3A0E)),
    );

    expect(issues.map((i) => i.token), ['accentInk']);
    expect(issues.single.problem, contains('drifted'));
  });

  test('hue distance wraps around the colour wheel', () {
    // A red fill at 358° and an ink at 2° are the same hue; a naive difference
    // would call it 356° of drift.
    final red = DashBrand(
      dark: const DashAccent(fill: Color(0xFFFF6B70), ink: Color(0xFFFF6B70)),
      light: const DashAccent(fill: Color(0xFFE0343A), ink: Color(0xFF9E1F1C)),
      onAccent: const Color(0xFF000000),
    );

    expect(
      dashContrastAudit(red).where((i) => i.problem.contains('drifted')),
      isEmpty,
    );
  });

  test('a label ink that disappears into the accent fill fails', () {
    const brand = DashBrand(
      dark: DashAccent(fill: Color(0xFF5FE08A), ink: Color(0xFF5FE08A)),
      light: DashAccent(fill: Color(0xFF34C46E), ink: Color(0xFF18733D)),
      onAccent: Color(0xFF2E8A50),
    );

    expect(
      dashContrastAudit(brand).map((i) => '${i.brightness.name} ${i.token}'),
      ['dark onAccent', 'light onAccent'],
    );
  });

  // Why the red and the yellow are two tokens each: the fill is too pale to be
  // read as a word on the light background, and the ink is the same hue
  // darkened until it is.
  test('a status fill is not readable text, and its ink is', () {
    for (final brightness in Brightness.values) {
      final t = DashTokens.resolve(brightness, green);
      expect(dashWorstContrast(t.dangerInk, t), greaterThanOrEqualTo(4.5));
      expect(dashWorstContrast(t.warningInk, t), greaterThanOrEqualTo(4.5));
    }
    const light = DashTokens.light(green);
    expect(dashWorstContrast(light.danger, light), lessThan(4.5));
    expect(dashWorstContrast(light.warning, light), lessThan(4.5));
  });
}
