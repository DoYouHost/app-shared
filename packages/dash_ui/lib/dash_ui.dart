/// The Dash design system shared by the DoYouHost applications.
///
/// Everything except the brand accent is common: the surfaces, the three text
/// inks, the secondary accents, the type scale, the radii and the Material
/// theme. The accent is a [DashBrand], handed to [buildDashThemeData], which
/// registers the resolved [DashTokens] on the theme so [DashTokens.of] finds
/// them anywhere below it.
///
/// Two things stay with the application: its wordmark, and anything that names
/// a widget for the diagnostic log — `app_diagnostics` is pinned per app, and a
/// dependency on it here would force both apps onto one ref.
///
/// The font families [DashTokens.fontUi] and [DashTokens.fontMono] are declared
/// by the application's pubspec, not bundled here: a package font would be
/// addressed as `packages/dash_ui/…` and every literal family in the apps would
/// stop matching it.
library;

export 'src/dash_brand.dart';
export 'src/dash_contrast.dart';
export 'src/dash_text.dart';
export 'src/dash_theme_data.dart';
export 'src/dash_tokens.dart';
export 'src/dash_widgets.dart';
