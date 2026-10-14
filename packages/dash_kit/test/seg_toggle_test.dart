import 'package:dash_kit/dash_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  testWidgets('a tap reports its value, and only the picked one is selected', (
    tester,
  ) async {
    final picked = <int>[];
    await pumpPhone(
      tester,
      Scaffold(
        body: DashSegToggle<int>(
          id: 'test.seg',
          selected: 1,
          segments: const [
            (value: 1, label: 'One', icon: null),
            (value: 2, label: 'Two', icon: Icons.star),
          ],
          onChanged: picked.add,
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    expect(picked, [2]);

    final tags = tester.widgetList<Semantics>(byLogId('test.seg')).toList();
    expect(tags.map((s) => s.properties.selected), [true, false]);
  });
}
