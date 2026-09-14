import 'package:flutter/material.dart';

/// One sentence to the user in a snack bar.
///
/// On the messenger rather than a context: a snack usually follows an `await`,
/// by which time the context may be gone, so the messenger is captured before
/// the request goes out.
extension DashSnack on ScaffoldMessengerState {
  void snack(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),

    /// Slides away the snack on screen first, so this one is not read as the
    /// answer to an older tap.
    bool replaceCurrent = false,

    /// Drops the whole queue instead — for controls a user can fire faster than
    /// a snack fades.
    bool clearQueue = false,

    /// Material keeps a snack with an action until it is dismissed; false lets
    /// it fade while the action stays tappable.
    bool? persist,
  }) {
    if (clearQueue) {
      clearSnackBars();
    } else if (replaceCurrent) {
      hideCurrentSnackBar();
    }
    showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        persist: persist,
      ),
    );
  }
}
