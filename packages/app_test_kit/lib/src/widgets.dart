import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every diagnostic identifier (`logTag` / `.tagged`) in the pumped tree.
Iterable<String> identifiersIn(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((s) => s.properties.identifier)
    .whereType<String>();

/// The node carrying one diagnostic identifier.
Finder byLogId(String id) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.identifier == id,
);

/// Three 350 ms frames in place of `pumpAndSettle`, for screens it can never
/// finish on (a blinking cursor).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 350));
  }
}

/// Drags the topmost list up [times] times: what sits below the fold of a lazy
/// list is not built, and a finder cannot tap it.
Future<void> scrollSheetDown(WidgetTester tester, {int times = 8}) async {
  for (var i = 0; i < times; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pump();
  }
}

/// A phone-shaped window instead of the default 800×600; [dp] is the logical
/// height. A tap below 1200 dp of content silently misses.
void usePhoneWindow(WidgetTester tester, {double dp = 800}) {
  const ratio = 3.0;
  tester.view.physicalSize = Size(360 * ratio, dp * ratio);
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
}
