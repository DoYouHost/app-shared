import 'package:dash_ui/dash_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'brands.dart';

void main() {
  Future<void> pumpButtons(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('text')),
              FilledButton(onPressed: () {}, child: const Text('filled')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color? inkOf<T extends Widget>(WidgetTester tester) => tester
      .widget<RichText>(
        find.descendant(of: find.byType(T), matching: find.byType(RichText)),
      )
      .text
      .style
      ?.color;

  for (final (name, brand) in [('green', green), ('gold', gold)]) {
    for (final brightness in Brightness.values) {
      final t = DashTokens.resolve(brightness, brand);

      // The apps dropped every per-call `foregroundColor: accentInk` on the
      // strength of this: a bare TextButton is painted with the ink already.
      testWidgets('$name ${brightness.name}: a bare TextButton is painted with '
          'the accent ink', (tester) async {
        await pumpButtons(tester, buildDashThemeData(brightness, brand: brand));

        expect(inkOf<TextButton>(tester), t.accentInk);
      });

      testWidgets('$name ${brightness.name}: a FilledButton is the accent fill '
          'with the on-accent ink', (tester) async {
        await pumpButtons(tester, buildDashThemeData(brightness, brand: brand));

        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(FilledButton),
            matching: find.byType(Material),
          ),
        );
        expect(material.color, t.accent);
        expect(inkOf<FilledButton>(tester), t.onAccent);
      });
    }
  }

  for (final brightness in Brightness.values) {
    final t = DashTokens.resolve(brightness, green);

    testWidgets('${brightness.name}: a destructive button is the readable red '
        'with a label that reads on it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDashThemeData(brightness, brand: green),
          home: Scaffold(
            body: FilledButton(
              style: dashDangerButtonStyle(t),
              onPressed: () {},
              child: const Text('delete'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, t.dangerInk);
      expect(inkOf<FilledButton>(tester), t.onDanger);
    });

    // Material paints a field's error text with `colorScheme.error`, so the
    // scheme carries the ink, not the fill.
    test(
      '${brightness.name}: the scheme\'s error colour is the readable red',
      () {
        final scheme = buildDashThemeData(brightness, brand: green).colorScheme;
        expect(scheme.error, t.dangerInk);
        expect(scheme.onError, t.onDanger);
      },
    );
  }

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('the icon in a button grows with the text at $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDashThemeData(Brightness.light, brand: green),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ),
          ),
        ),
      );

      // A Material button icon is 18 dp.
      expect(tester.getSize(find.byIcon(Icons.add)).width, 18 * scale);
    });
  }

  test('the scaffold is the brand\'s', () {
    const scaffold = Color(0xFF0B0D10);
    final brand = DashBrand(
      dark: green.dark,
      light: green.light,
      onAccent: green.onAccent,
      darkSurfaces: const DashSurfaces(
        glow: Color(0xFF131A12),
        middle: Color(0xFF07090A),
        edge: Color(0xFF050605),
        cardEnd: Color(0x04FFFFFF),
        overlay: Color(0xFF0E1310),
        scaffold: scaffold,
      ),
    );

    expect(
      buildDashThemeData(Brightness.dark, brand: brand).scaffoldBackgroundColor,
      scaffold,
    );
    expect(
      buildDashThemeData(
        Brightness.light,
        brand: green,
      ).scaffoldBackgroundColor,
      const Color(0xFFFDFEFC),
    );
  });
}
