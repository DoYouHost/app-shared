import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';

import '../l10n/report_localizations.dart';

extension ReportSnack on ScaffoldMessengerState {
  /// Slides away whatever snack is showing first: every sentence this flow says
  /// answers the tap just made, and one queued behind an older answer would
  /// arrive reading as a reply to something else.
  void replaceSnack(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    hideCurrentSnackBar();
    showSnackBar(
      SnackBar(content: Text(message), action: action, duration: duration),
    );
  }
}

/// A yes/no question whose yes destroys something. The confirmation is a
/// filled, red button, so the destructive answer does not look like the way
/// out, and both buttons are named in the log as `<id>.confirm` and
/// `<id>.cancel`.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String id,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final l10n = ReportLocalizations.of(context);
  final t = DashTokens.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.reportCancel),
        ).tagged('$id.cancel'),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: t.danger),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ).tagged('$id.confirm'),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Centres [child] and caps its width, when the application asked for a cap.
class MaxContentWidth extends StatelessWidget {
  const MaxContentWidth({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double? maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth;
    if (width == null) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}
