import 'package:dash_kit/dash_kit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// The guidelines compare semantics rects with 48 in physical pixels, so the
/// default 3x test window lets a 36 dp target pass. Widgets are centred too: a
/// node touching the window edge is skipped as possibly scrolled off.
void logicalPixels(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a segment toggle meets the Android 48 dp target', (
    tester,
  ) async {
    logicalPixels(tester);
    final handle = tester.ensureSemantics();
    await pumpPhone(
      tester,
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: DashSegToggle<int>(
              id: 'test.seg',
              selected: 1,
              segments: const [
                (value: 1, label: 'One', icon: null),
                (value: 2, label: 'Two', icon: null),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('a compact stepper meets the Android 48 dp target', (
    tester,
  ) async {
    logicalPixels(tester);
    final handle = tester.ensureSemantics();
    await pumpPhone(
      tester,
      Scaffold(
        body: Center(
          child: DashStepper(
            value: 2,
            min: 0,
            max: 5,
            compact: true,
            lessId: 'test.less',
            moreId: 'test.more',
            lessTooltip: 'Fewer',
            moreTooltip: 'More',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('the filter button announces what it opens', (tester) async {
    logicalPixels(tester);
    final handle = tester.ensureSemantics();
    await pumpPhone(
      tester,
      Scaffold(
        body: Center(
          child: FilterButton(
            count: 0,
            tooltip: 'Filters',
            id: 'test.filters',
            onTap: () {},
          ),
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(find.bySemanticsLabel('Filters'), findsWidgets);
    handle.dispose();
  });

  testWidgets(
    'a filterable select keeps its field at 48 dp and names its arrow',
    (tester) async {
      logicalPixels(tester);
      final handle = tester.ensureSemantics();
      await pumpPhone(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: Builder(
                builder: (context) => dashCombo<int>(
                  context,
                  id: 'test.combo',
                  label: const Text('Printer'),
                  filterable: true,
                  initialSelection: 1,
                  entries: const [DropdownMenuEntry(value: 1, label: 'One')],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(DropdownMenu<int>)).height, 48);
      final arrow = find.semantics.byPredicate(
        (node) =>
            node.tags?.any((tag) => '$tag'.contains('suffixIcon')) ?? false,
      );
      final node = arrow.evaluate().single;
      expect(node.rect.width, greaterThanOrEqualTo(40));
      expect(node.rect.height, greaterThanOrEqualTo(40));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    },
  );
}
