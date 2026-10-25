import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const navBar = 48.0;
  final contentKey = UniqueKey();

  testWidgets('a surface sheet reserves the same strip itself', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: navBar),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SheetSurface(child: SizedBox(key: contentKey)),
        ),
      ),
    );

    final surfaceBottom = tester.getRect(find.byType(SheetSurface)).bottom;
    final contentBottom = tester.getRect(find.byKey(contentKey)).bottom;
    expect(surfaceBottom - contentBottom, navBar);
  });

  testWidgets('an open keyboard already covers that strip', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: navBar),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SheetSurface(child: SizedBox(key: contentKey)),
        ),
      ),
    );

    final surfaceBottom = tester.getRect(find.byType(SheetSurface)).bottom;
    final contentBottom = tester.getRect(find.byKey(contentKey)).bottom;
    expect(surfaceBottom - contentBottom, 0);
  });

  testWidgets('the sheet is painted with the brand\'s overlay', (tester) async {
    const overlay = Color(0xFF101820);
    const brand = DashBrand(
      dark: DashAccent(fill: Color(0xFF5FE08A), ink: Color(0xFF5FE08A)),
      light: DashAccent(fill: Color(0xFF34C46E), ink: Color(0xFF18733D)),
      onAccent: Color(0xFF0A0C08),
      darkSurfaces: DashSurfaces(
        glow: Color(0xFF131A12),
        middle: Color(0xFF07090A),
        edge: Color(0xFF050605),
        cardEnd: Color(0x04FFFFFF),
        overlay: overlay,
        scaffold: Color(0xFF07090A),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDashThemeData(Brightness.dark, brand: brand),
        home: SheetSurface(child: SizedBox(key: contentKey)),
      ),
    );

    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SheetSurface),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, overlay);
    expect(
      (decoration.border! as Border).top.color,
      const DashTokens.dark(brand).overlayBorder,
    );
  });
}
