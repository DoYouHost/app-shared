import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The families the Dash type scale is set in. Each application declares the
/// faces in its own pubspec — a package font would be addressed as
/// `packages/dash_ui/…` and every literal family name would stop matching —
/// but the licence that has to travel with them ships here, so a second
/// application cannot forget it.
const _dashFontLicenses = {
  'Manrope': 'packages/dash_ui/assets/licenses/OFL-Manrope.txt',
  'JetBrains Mono': 'packages/dash_ui/assets/licenses/OFL-JetBrainsMono.txt',
};

/// Adds the OFL texts of the Dash fonts to the licence page.
///
/// Flutter collects licences from pub packages by itself; a bundled `.ttf` is
/// not one, so without this call the fonts the app is set in appear nowhere —
/// which the OFL does not allow, since the licence has to be distributed with
/// the font. Call it from `main`, before `runApp`; the registry reads the
/// entries lazily, so it costs nothing until someone opens the page.
///
/// Once per process: the registry does not deduplicate collectors, so a second
/// call lists both faces twice.
void registerDashFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: path)
        in _dashFontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString(path));
    }
  });
}
