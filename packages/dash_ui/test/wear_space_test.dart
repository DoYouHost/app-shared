import 'package:dash_ui/dash_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("the watch's scale is Wear Material 3's", () {
    // compose-material3 1.7.1: ButtonDefaults.ButtonHorizontalPadding,
    // ButtonVerticalPadding; the Wear OS list guidance for the gaps.
    expect(WearSpace.buttonHorizontal, 14);
    expect(WearSpace.buttonVertical, 6);
    expect(WearSpace.inGroup, 4);
    expect(WearSpace.betweenGroups, 8);
    expect(WearSpace.titleToContent, 12);
    expect(WearSpace.betweenSections, 16);
  });
}
