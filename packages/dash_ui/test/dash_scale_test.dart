import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the icon and radius scales are on the 4 dp grid and never close', () {
    const icons = [
      DashIcon.xs,
      DashIcon.sm,
      DashIcon.md,
      DashIcon.lg,
      DashIcon.xl,
      DashIcon.xxl,
    ];
    const radii = [
      DashRadius.xs,
      DashRadius.sm,
      DashRadius.md,
      DashRadius.lg,
      DashRadius.xl,
    ];
    for (final scale in [icons, radii]) {
      for (final v in scale) {
        expect(v % 4, 0, reason: '$v is off the grid');
      }
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i] - scale[i - 1], greaterThanOrEqualTo(4));
      }
    }
    expect(DashRadius.pill, greaterThan(DashRadius.xl));
  });

  test('the bar heights are on the grid', () {
    expect(DashBar.thin % 4, 0);
    expect(DashBar.thick % 4, 0);
    expect(DashBar.thick, greaterThan(DashBar.thin));
  });

  test('the alphas rise and are far enough apart to tell', () {
    const alphas = [
      DashAlpha.faint,
      DashAlpha.wash,
      DashAlpha.soft,
      DashAlpha.outline,
      DashAlpha.scrim,
      DashAlpha.strong,
      DashAlpha.heavy,
      DashAlpha.cover,
    ];
    for (var i = 1; i < alphas.length; i++) {
      expect(alphas[i] - alphas[i - 1], greaterThanOrEqualTo(0.06));
    }
    expect(DashAlpha.wash, 0.14);
    expect(DashAlpha.outline, 0.4);
    expect(DashAlpha.scrim, 0.5);
    expect(DashAlpha.cover, 0.95);
  });

  test('the font sizes are the type scale and rise', () {
    const sizes = [
      DashFontSize.micro,
      DashFontSize.label,
      DashFontSize.body,
      DashFontSize.title,
      DashFontSize.lead,
      DashFontSize.heading,
      DashFontSize.display,
      DashFontSize.hero,
      DashFontSize.numeral,
    ];
    for (var i = 1; i < sizes.length; i++) {
      expect(sizes[i], greaterThan(sizes[i - 1]));
    }
  });

  testWidgets('dashLargeText turns on above 1.3 and not at it', (tester) async {
    Future<bool> at(double scale) async {
      late bool result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Builder(
            builder: (context) {
              result = dashLargeText(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    expect(await at(1.0), isFalse);
    expect(await at(1.3), isFalse);
    expect(await at(1.31), isTrue);
    expect(await at(2.0), isTrue);
  });
}
