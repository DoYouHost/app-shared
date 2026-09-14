import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';

/// Asks before doing something. `true` only when the user confirms; the cancel
/// button, the barrier and back all answer `false`.
///
/// Both answers are filled buttons sharing the width equally: dismiss on the
/// left, confirm on the right. [destructive] paints the confirm in the danger
/// red; otherwise it takes the brand accent, for a question where nothing is
/// lost either way.
///
/// [id] names the dialog in the log. The buttons are tagged `<id>.cancel` and
/// `<id>.confirm`, and the answer is recorded as a `confirm` record — a dialog is
/// its own route, so without that a log cannot tell "confirmed" from "backed
/// out" except by guessing from whether a request followed. The title and
/// message are user-facing text and never go in.
///
/// Keep [confirmLabel] to the verb and let [title] name the thing: each half
/// holds about ten characters per line on a phone.
Future<bool> confirmDialog(
  BuildContext context, {
  required String id,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final t = DashTokens.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => logSurface(
      id,
      AlertDialog(
        icon: icon == null ? null : Icon(icon),
        title: Text(title),
        content: Text(message),
        actions: [
          // The actions sit in an OverflowBar, which offers its children
          // unbounded width; the widest possible child makes it hand this one
          // exactly the dialog's.
          SizedBox(
            width: double.maxFinite,
            // Equal height even when one label wraps and the other does not.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FilledButton(
                      style: dashNeutralButtonStyle(t),
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(
                        cancelLabel ??
                            MaterialLocalizations.of(
                              dialogContext,
                            ).cancelButtonLabel,
                        textAlign: TextAlign.center,
                      ),
                    ).tagged('$id.cancel'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: destructive ? dashDangerButtonStyle(t) : null,
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(confirmLabel, textAlign: TextAlign.center),
                    ).tagged('$id.confirm'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  final answer = confirmed ?? false;
  DiagnosticRecorder.active?.add(
    LogSource.ui,
    'confirm',
    fields: {'id': id, 'reason': answer ? 'confirmed' : 'cancelled'},
  );
  return answer;
}

/// The answer that backs out: [dashPrimaryButtonStyle]'s shape and padding, so
/// it stands the same height as the button beside it, on a quiet fill of the
/// text colour.
ButtonStyle dashNeutralButtonStyle(
  DashTokens t,
) => dashPrimaryButtonStyle(t).copyWith(
  backgroundColor: WidgetStateProperty.resolveWith(
    (states) => t.textPrimary.withValues(
      alpha: states.contains(WidgetState.disabled) ? 0.04 : 0.09,
    ),
  ),
  foregroundColor: WidgetStateProperty.resolveWith(
    (states) =>
        states.contains(WidgetState.disabled) ? t.textTertiary : t.textPrimary,
  ),
  overlayColor: WidgetStatePropertyAll(t.textPrimary.withValues(alpha: 0.06)),
);
