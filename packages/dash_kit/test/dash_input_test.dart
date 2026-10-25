import 'package:dash_kit/dash_kit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Three 350 ms frames in place of `pumpAndSettle`: a focused combo's cursor
/// blinks, so the tree never settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 350));
  }
}

Iterable<String> _identifiers(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((s) => s.properties.identifier)
    .whereType<String>();

void main() {
  /// A `DropdownMenu` builds its own field, so it takes a theme instead of a
  /// decoration — and the two used to be written out separately and drift. They
  /// are now one source; this is the test that says so.
  for (final tokens in [
    const DashTokens.dark(testBrand),
    const DashTokens.light(testBrand),
  ]) {
    final name = tokens.isDark ? 'dark' : 'light';

    test('the dropdown theme carries the field chrome ($name)', () {
      final field = dashFieldDecoration(tokens);
      final menu = dashInputTheme(tokens);

      expect(menu.fillColor, field.fillColor);
      expect(menu.labelStyle, field.labelStyle);
      expect(menu.floatingLabelStyle, field.floatingLabelStyle);
      expect(menu.hintStyle, field.hintStyle);
      expect(menu.helperStyle, field.helperStyle);
      expect(menu.border, field.border);
      expect(menu.enabledBorder, field.enabledBorder);
      expect(menu.focusedBorder, field.focusedBorder);
      expect(menu.errorBorder, field.errorBorder);
      expect(menu.focusedErrorBorder, field.focusedErrorBorder);
      expect(menu.isDense, isTrue);
      expect(menu.filled, isTrue);
    });

    test('a hint of two sentences wraps on both kinds of field ($name)', () {
      expect(dashDecoration(tokens).helperMaxLines, greaterThan(1));
      expect(dashInputTheme(tokens).helperMaxLines, greaterThan(1));
    });

    test('the form decoration is the same chrome, suffix included ($name)', () {
      final plain = dashFieldDecoration(tokens, suffixText: 'g');
      final shared = dashDecoration(tokens, suffixText: 'g');

      expect(shared.labelStyle, plain.labelStyle);
      expect(shared.suffixStyle, plain.suffixStyle);
      expect(shared.suffixText, 'g');
      expect(shared.focusedBorder, plain.focusedBorder);
    });
  }

  /// The picker field bambuddy's forms share. What each of them depends on is
  /// the same three things: which of value and placeholder is showing, that a
  /// placeholder is visibly not a value, and that the clear button exists only
  /// while there is something to clear.
  group('dashPickerField', () {
    var opened = 0;
    setUp(() => opened = 0);

    Future<void> pump(
      WidgetTester tester, {
      String? value,
      ({String id, String tooltip, VoidCallback onPressed})? clear,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: testTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: dashPickerField(
              context,
              id: 'test.field',
              label: 'Label',
              placeholder: 'Nothing picked',
              value: value,
              clear: clear,
              onTap: () => opened++,
            ),
          ),
        ),
      ),
    );

    Color colourOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;

    testWidgets(
      'an empty value shows the placeholder, and shows that it is one',
      (tester) async {
        await pump(tester);
        final t = DashTokens.of(tester.element(find.text('Nothing picked')));

        expect(colourOf(tester, 'Nothing picked'), t.textTertiary);
      },
    );

    testWidgets('a value reads as one, in the primary ink', (tester) async {
      await pump(tester, value: 'Basic');
      final t = DashTokens.of(tester.element(find.text('Basic')));

      expect(colourOf(tester, 'Basic'), t.textPrimary);
      expect(find.text('Nothing picked'), findsNothing);
    });

    testWidgets('the clear button appears only once something is picked, and '
        'takes the tap without opening the picker under it', (tester) async {
      var cleared = 0;
      final clear = (
        id: 'test.field.clear',
        tooltip: 'Clear',
        onPressed: () => cleared++,
      );

      await pump(tester, clear: clear);
      expect(find.byIcon(Icons.clear), findsNothing);

      await pump(tester, value: 'Basic', clear: clear);
      expect(
        find.byTooltip('Clear'),
        findsOneWidget,
        reason: 'the caller names the button for a screen reader',
      );
      await tester.tap(find.byIcon(Icons.clear));

      expect(cleared, 1);
      // A control inside a control: the inner one has to win in its own box,
      // or clearing the field would open the picker it just emptied.
      expect(opened, 0);
    });

    testWidgets('keyboard focus is visible — the decorator is told it has it', (
      tester,
    ) async {
      await pump(tester);
      expect(
        tester.widget<InputDecorator>(find.byType(InputDecorator)).isFocused,
        isFalse,
      );

      // What a Tab press does, without depending on what else is on screen.
      Focus.of(tester.element(find.byType(InputDecorator))).requestFocus();
      await tester.pump();

      expect(
        tester.widget<InputDecorator>(find.byType(InputDecorator)).isFocused,
        isTrue,
      );
    });

    testWidgets('a field with no clear callback never grows one', (
      tester,
    ) async {
      await pump(tester, value: 'Basic');

      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });
  });

  /// The filter combo: one shape for every "no filter" select. What they all
  /// depend on: the any-row reads as null, it is what shows when nothing is
  /// picked, and no call site needs a stand-in value to say "no filter".
  group('dashAnyOrOne', () {
    late List<int?> picked;
    setUp(() => picked = []);

    Future<void> pump(WidgetTester tester, {int? selected}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: dashAnyOrOne<int>(
                  context,
                  id: 'test.filter',
                  anyLabel: 'Any',
                  selected: selected,
                  options: const [(3, 'Three'), (4, 'Four')],
                  onPick: picked.add,
                ),
              ),
            ),
          ),
        );

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('nothing picked shows the any-row, not an empty field', (
      tester,
    ) async {
      // The reason no sentinel is needed: `initialSelection: null` resolves
      // against the null row, so the field names the state it is in. A
      // stand-in value was introduced on the belief that it could not.
      await pump(tester);

      expect(fieldText(tester), 'Any');
    });

    testWidgets('a set filter shows its own label', (tester) async {
      await pump(tester, selected: 4);

      expect(fieldText(tester), 'Four');
    });

    testWidgets('choosing a value reports the value', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(DropdownMenu<int?>));
      await _settle(tester);
      await tester.tap(find.text('Three').last);
      await _settle(tester);

      expect(picked, [3]);
    });

    testWidgets('choosing the any-row reports null, not a stand-in', (
      tester,
    ) async {
      // The half every caller depends on: one "no filter" state, so a screen
      // never has to map a magic value back before writing its query.
      await pump(tester, selected: 4);
      await tester.tap(find.byType(DropdownMenu<int?>));
      await _settle(tester);
      await tester.tap(find.text('Any').last);
      await _settle(tester);

      expect(picked, [null]);
    });

    testWidgets('every value row records under one id, the any-row its own', (
      tester,
    ) async {
      // Labels are names people gave things and stay out of the log, so which
      // row it was is deliberately not recoverable — only that it was a row.
      await pump(tester);
      await tester.tap(find.byType(DropdownMenu<int?>));
      await _settle(tester);

      expect(
        find.bySemanticsLabel(RegExp('.*')).evaluate().isNotEmpty,
        isTrue,
        reason: 'the menu opened',
      );
      final ids = _identifiers(
        tester,
      ).where((id) => id.startsWith('test.filter')).toSet();
      expect(ids, containsAll(['test.filter.any', 'test.filter.option']));
    });
  });

  group('dashCombo shows what is selected', () {
    /// What every converted select leans on: the field displays the *label* of
    /// `initialSelection`, so a form opened on an existing row reads as filled
    /// in rather than blank.
    Future<void> pump(WidgetTester tester, {int? selection}) =>
        tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: dashCombo<int>(
                  context,
                  id: 'test.combo',
                  initialSelection: selection,
                  entries: const [
                    DropdownMenuEntry(value: 3, label: 'Three'),
                    DropdownMenuEntry(value: 4, label: 'Four'),
                  ],
                ),
              ),
            ),
          ),
        );

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('an existing value names itself in the field', (tester) async {
      await pump(tester, selection: 4);

      expect(fieldText(tester), 'Four');
    });

    testWidgets('a selection no longer among the entries leaves the old text', (
      tester,
    ) async {
      // Not a defect to fix here — Flutter re-seeds the field only when the
      // new selection is found (`DropdownMenu.didUpdateWidget`). It is why the
      // a caller whose entries change under it gives the field a `ValueKey`:
      // without a fresh element it keeps naming the old selection.
      await pump(tester, selection: 4);
      await pump(tester, selection: 9);

      expect(fieldText(tester), 'Four');
    });

    testWidgets('a select is exactly as tall as a field beside it', (
      tester,
    ) async {
      // Forms put the two in one `Row`, so a difference of a few pixels reads
      // as a rendering fault rather than as a style. The select used to run
      // 56 against the field's dense 48: Flutter hands its arrow a bare
      // `IconButton`, which claims the full 48x48 tap target and pushes the
      // whole field out.
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Builder(
            builder: (context) {
              final t = DashTokens.of(context);
              return Scaffold(
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: dashCombo<String>(
                        context,
                        id: 'test.height',
                        label: const Text('Type'),
                        initialSelection: 'a',
                        entries: const [
                          DropdownMenuEntry(value: 'a', label: 'A'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: '100',
                        decoration: dashFieldDecoration(t, labelText: 'Amount'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await _settle(tester);

      expect(
        tester.getSize(find.byType(DropdownMenu<String>)).height,
        tester.getSize(find.byType(TextFormField)).height,
      );
    });

    testWidgets('a caller\'s own chrome gets the arrow boxed too', (
      tester,
    ) async {
      // A caller may pass its own theme, for a screen that is still plain
      // Material. It must not pay for that with the 8px the shared theme no
      // longer costs.
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: dashCombo<String>(
                      context,
                      id: 'test.raw',
                      label: const Text('Type'),
                      initialSelection: 'a',
                      decorationTheme: const InputDecorationTheme(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      entries: const [
                        DropdownMenuEntry(value: 'a', label: 'A'),
                      ],
                    ),
                  ),
                  const Expanded(
                    // Keyed, not found by type: a `DropdownMenu` builds a
                    // `TextField` of its own, so `find.byType` would hand the
                    // comparison the select's own field and pass whatever
                    // happened.
                    child: TextField(
                      key: Key('neighbour'),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      expect(
        tester.getSize(find.byType(DropdownMenu<String>)).height,
        tester.getSize(find.byKey(const Key('neighbour'))).height,
      );
    });

    testWidgets('a caller that boxes the arrow itself is left alone', (
      tester,
    ) async {
      // The default is a floor under a known Flutter default, not a house
      // style: a caller who has measured its own screen keeps what it asked
      // for.
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: dashCombo<String>(
                context,
                id: 'test.own_arrow',
                initialSelection: 'a',
                decorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                  suffixIconConstraints: BoxConstraints.tightFor(
                    width: 56,
                    height: 56,
                  ),
                ),
                entries: const [DropdownMenuEntry(value: 'a', label: 'A')],
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      final menu = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(
        menu.inputDecorationTheme?.suffixIconConstraints,
        const BoxConstraints.tightFor(width: 56, height: 56),
      );
    });
  });

  // Dense fields drew 45 dp, under the 48 dp androidTapTargetGuideline asks for.
  testWidgets('a field is at least a touch target tall', (tester) async {
    const tokens = DashTokens.dark(testBrand);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDashThemeData(Brightness.dark, brand: testBrand),
        home: Scaffold(
          body: Column(
            children: [
              // The test font's line is taller than the app's, so a small one
              // stands in for the real fields the dense inset left at 45 dp.
              TextField(
                style: const TextStyle(fontSize: 10),
                decoration: dashFieldDecoration(tokens, labelText: 'A'),
              ),
              const TextField(style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );

    for (final field in tester.widgetList(find.byType(TextField))) {
      expect(
        tester.getSize(find.byWidget(field)).height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
      );
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
