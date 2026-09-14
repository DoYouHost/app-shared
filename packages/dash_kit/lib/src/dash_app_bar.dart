import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dash_ui/dash_ui.dart' as dash;
import 'package:flutter/material.dart';

/// Names a hand-built [AppBar] `chrome.appbar` in the log without restyling it.
///
/// The framework's back button cannot be tagged on its own; wrapping the bar
/// names it by inheritance. The bar's own preferred size is kept, so a bar with
/// a `bottom:` is not clipped.
PreferredSizeWidget loggedAppBar(AppBar bar) => PreferredSize(
  preferredSize: bar.preferredSize,
  child: logTag('chrome.appbar', bar),
);

/// `dash_ui`'s app bar, named for the log through [loggedAppBar].
PreferredSizeWidget dashAppBar(
  BuildContext context, {
  String? title,
  Widget? titleWidget,
  List<Widget>? actions,
  Widget? leading,
  PreferredSizeWidget? bottom,
  bool automaticallyImplyLeading = true,
}) => loggedAppBar(
  dash.dashAppBar(
    context,
    title: title,
    titleWidget: titleWidget,
    actions: actions,
    leading: leading,
    bottom: bottom,
    automaticallyImplyLeading: automaticallyImplyLeading,
  ),
);

/// A form's confirming app-bar action — "Save", "Create".
///
/// [busy] disables it while the submit is in flight, which is the only thing
/// stopping a second tap from posting the form twice.
Widget dashSaveAction({
  required String id,
  required String label,
  required bool busy,
  required VoidCallback onPressed,
}) => TextButton(
  onPressed: busy ? null : onPressed,
  child: Text(label),
).tagged(id);
