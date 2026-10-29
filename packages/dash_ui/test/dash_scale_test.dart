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
    ];
    const radii = [DashRadius.sm, DashRadius.md, DashRadius.lg, DashRadius.xl];
    for (final scale in [icons, radii]) {
      for (final v in scale) {
        expect(v % 4, 0, reason: '$v is off the grid');
      }
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i] - scale[i - 1], greaterThanOrEqualTo(4));
      }
    }
  });

  test('the bar heights are on the grid', () {
    expect(DashBar.thin % 4, 0);
    expect(DashBar.thick % 4, 0);
    expect(DashBar.thick, greaterThan(DashBar.thin));
  });

  test('the alphas keep the values the pill and the theme were drawn with', () {
    expect(DashAlpha.wash, 0.16);
    expect(DashAlpha.outline, 0.4);
    expect(DashAlpha.scrim, 0.5);
    expect(DashAlpha.cover, 0.95);
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
