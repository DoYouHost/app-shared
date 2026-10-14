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
export 'src/dash_icon_tile.dart';
export 'src/dash_input.dart';
export 'src/dash_progress_bar.dart';
export 'src/dash_search_field.dart';
export 'src/dash_sheet.dart';
export 'src/dash_snack.dart';
export 'src/dash_stepper.dart';
export 'src/dashed_line.dart';
export 'src/date_picker.dart';
export 'src/filter_controls.dart';
export 'src/inline_note.dart';
export 'src/max_content_width.dart';
export 'src/progress.dart';
export 'src/prompt_name_dialog.dart';
export 'src/refresh_when_shown.dart';
export 'src/screen_padding.dart';
export 'src/section_heading.dart';
export 'src/seg_toggle.dart';
export 'src/settings_entry_tile.dart';
export 'src/settings_rows.dart';
export 'src/sliver_search_bar.dart';
export 'src/state_views.dart';
export 'src/system_insets.dart';
export 'src/tappable_card.dart';
export 'src/thumbnail_box.dart';
