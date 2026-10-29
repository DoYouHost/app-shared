import 'package:dash_ui/dash_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("the watch's font sizes rise on a 2 sp grid and keep Play's floor", () {
    const sizes = [
      WearFontSize.fine,
      WearFontSize.body,
      WearFontSize.title,
      WearFontSize.hero,
    ];
    for (final s in sizes) {
      expect(s % 2, 0, reason: '$s is off the grid');
    }
    for (var i = 1; i < sizes.length; i++) {
      expect(sizes[i] - sizes[i - 1], greaterThanOrEqualTo(2));
    }
    // WO-V14: 12 sp for essential text, 10 sp only for fine print.
    expect(WearFontSize.body, greaterThanOrEqualTo(12));
    expect(WearFontSize.fine, greaterThanOrEqualTo(10));
  });
}
