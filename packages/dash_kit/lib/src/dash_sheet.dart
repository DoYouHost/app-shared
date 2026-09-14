import 'package:flutter/material.dart';

/// Scrim behind a sheet that draws its own surface: darker than Material's, so
/// the screen underneath reads as a dimmed backdrop rather than a half-rendered
/// glitch bleeding through the sheet's rounded top.
const Color dashSheetBarrier = Color(0xB3000000);

/// A bottom sheet with a drag handle and its content kept above the system
/// navigation bar.
///
/// The inset is why this exists. Since Android 15 a sheet is drawn edge to
/// edge, so without a bottom [SafeArea] its last row — a form's Save button —
/// lands under the navigation bar. A [SafeArea] the content carries itself
/// stays harmless: this one consumes the inset first.
///
/// The width needs no argument: Material 3 already caps a sheet at 640 dp.
///
/// [scrollControlled] lets the sheet grow past 9/16 of the screen; pass false
/// for a short list of actions. [dismissible] false holds the sheet open against
/// the barrier and a drag alike, and drops the handle that would invite one.
Future<T?> dashSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollControlled = true,
  bool dismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: scrollControlled,
  showDragHandle: dismissible,
  isDismissible: dismissible,
  enableDrag: dismissible,
  // Covers the top for a sheet that reaches full height; the bottom is the
  // SafeArea below.
  useSafeArea: true,
  builder: (sheetContext) => SafeArea(top: false, child: builder(sheetContext)),
);

/// A transparent, unbounded sheet for content that draws its own surface —
/// corners, handle and inset included — usually inside a
/// `DraggableScrollableSheet`.
///
/// Pass a null [barrierColor] to keep Material's lighter scrim.
Future<T?> dashSurfaceSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? barrierColor = dashSheetBarrier,
  bool dismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: barrierColor,
  isDismissible: dismissible,
  enableDrag: dismissible,
  builder: builder,
);
