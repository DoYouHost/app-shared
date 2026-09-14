/// The Dash widgets that name themselves in the diagnostic log.
///
/// `dash_ui` stays free of `app_diagnostics`; this is the layer that joins the
/// two. Everything here existed in at least two copies across bambuddy-mobile,
/// lubelogger-mobile and `app_report_ui`, and the copies had drifted apart in
/// look as well as in what they logged.
///
/// It re-exports `dash_ui` with its own [dashAppBar] in place of the untagged
/// one, so an application imports this library instead of `dash_ui`, never both.
library;

export 'package:dash_ui/dash_ui.dart' hide dashAppBar;

export 'src/button_pair.dart';
export 'src/confirm_dialog.dart';
export 'src/dash_app_bar.dart';
export 'src/dash_sheet.dart';
export 'src/dash_snack.dart';
export 'src/max_content_width.dart';
export 'src/progress.dart';
export 'src/section_heading.dart';
export 'src/state_views.dart';
export 'src/system_insets.dart';
