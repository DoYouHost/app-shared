import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  testWidgets('both bundled families reach the licence page', (tester) async {
    registerDashFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final packages = {for (final entry in entries) ...entry.packages};
    expect(packages, {'Manrope', 'JetBrains Mono'});
    // The OFL itself, not an empty file or a 404 page.
    expect(
      entries.first.paragraphs.map((p) => p.text).join(' '),
      contains('SIL Open Font License'),
    );
  });
}
