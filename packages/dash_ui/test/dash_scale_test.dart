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

  test('the weights rise by at least a hundred', () {
    const weights = [
      DashWeight.regular,
      DashWeight.medium,
      DashWeight.semibold,
      DashWeight.bold,
    ];
    for (var i = 1; i < weights.length; i++) {
      expect(
        weights[i].value - weights[i - 1].value,
        greaterThanOrEqualTo(100),
      );
    }
  });

  test('the strokes, blurs and trackings rise and are told apart', () {
    const strokes = [DashStroke.hairline, DashStroke.regular, DashStroke.heavy];
    const blurs = [DashBlur.sm, DashBlur.md, DashBlur.lg];
    const tracking = [
      DashTracking.tight,
      DashTracking.label,
      DashTracking.caps,
      DashTracking.wide,
    ];
    for (final scale in [strokes, blurs, tracking]) {
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    }
    expect(DashTracking.tight, lessThan(0));
  });

  test('the size ladder rises and its steps widen', () {
    const ladder = [
      DashSize.d4,
      DashSize.d8,
      DashSize.d12,
      DashSize.d16,
      DashSize.d20,
      DashSize.d24,
      DashSize.d32,
      DashSize.d40,
      DashSize.d48,
      DashSize.d56,
      DashSize.d64,
      DashSize.d72,
      DashSize.d80,
      DashSize.d96,
      DashSize.d112,
      DashSize.d128,
      DashSize.d160,
      DashSize.d192,
      DashSize.d240,
      DashSize.d320,
    ];
    var previousStep = 0.0;
    for (var i = 1; i < ladder.length; i++) {
      final step = ladder[i] - ladder[i - 1];
      expect(step, greaterThanOrEqualTo(previousStep), reason: '${ladder[i]}');
      previousStep = step;
      expect(ladder[i] % 4, 0);
    }
    expect(DashSize.d48, 48);
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
