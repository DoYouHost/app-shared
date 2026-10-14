import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/widgets.dart';

import 'system_insets.dart';

/// The padding of every screen's scrolling body: the gutter at the sides, [sm]
/// above, [bottom] below, plus the system navigation bar. Seven variants of it
/// were typed out by hand before; a list under a FAB passes
/// `DashSpace.fabClearance`.
EdgeInsets screenListPadding(
  BuildContext context, {
  double bottom = DashSpace.xl,
}) => withSystemNavInset(
  context,
  const EdgeInsets.fromLTRB(
    DashSpace.gutter,
    DashSpace.sm,
    DashSpace.gutter,
    0,
  ).copyWith(bottom: bottom),
);
