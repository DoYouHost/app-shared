import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';

/// Records that a screen showed one of these instead of its content.
///
/// The only lane that says what the user saw: from the request alone, "cannot
/// load" and "nothing here" are indistinguishable — a 200 with an empty list
/// produces the second. Logged from `initState`, so a rebuilding screen adds
/// one record rather than one per frame. The message never goes in; it is
/// localized text, and the surface already says where the user was.
void _logState(String evt, BuildContext context, String? surface) =>
    DiagnosticRecorder.active?.add(
      LogSource.ui,
      evt,
      lvl: LogLevel.warn,
      fields: {'surface': surface ?? LogSurface.of(context)},
    );

/// "Failed to load" with a retry button, centred in the space it is given.
class AsyncErrorView extends StatefulWidget {
  const AsyncErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
    this.icon = Icons.cloud_off,
    this.tonal = false,
    this.scrollable = false,
    this.surface,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  /// Null hides the glyph, for a compact slot.
  final IconData? icon;

  final bool tonal;

  /// Makes the view its own scroll view, so an enclosing [RefreshIndicator]
  /// has something to pull. The message stays centred either way. Leave it off
  /// where the view sits inside another scroll view.
  final bool scrollable;

  /// Which screen failed, for the log; defaults to the enclosing surface.
  final String? surface;

  @override
  State<AsyncErrorView> createState() => _AsyncErrorViewState();
}

class _AsyncErrorViewState extends State<AsyncErrorView> {
  @override
  void initState() {
    super.initState();
    _logState('error_view', context, widget.surface);
  }

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final icon = widget.icon;
    final retry = widget.tonal
        ? FilledButton.tonal(
            onPressed: widget.onRetry,
            child: Text(widget.retryLabel),
          )
        : FilledButton(
            onPressed: widget.onRetry,
            child: Text(widget.retryLabel),
          );
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: t.textTertiary),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(widget.message, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            retry.tagged('error.retry'),
          ],
        ),
      ),
    );

    if (!widget.scrollable) return content;
    // A list one viewport tall, so the message is centred exactly as without
    // it and a pull still has a scroll view to drag.
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : 0,
            ),
            child: content,
          ),
        ],
      ),
    );
  }
}

/// An icon and a message where a list would be.
class EmptyStateView extends StatefulWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    required this.icon,
    this.surface,
    this.scrollable = true,
  });

  final String message;
  final IconData icon;

  /// Which screen is empty, for the log; defaults to the enclosing surface.
  final String? surface;

  /// A list of its own, so pull-to-refresh still works on an empty screen.
  /// Pass false inside someone else's scroll view: a viewport nested in a
  /// viewport has no height to expand into.
  final bool scrollable;

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView> {
  @override
  void initState() {
    super.initState();
    _logState('empty_view', context, widget.surface);
  }

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    final body = Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(widget.icon, size: 48, color: t.textTertiary),
          const SizedBox(height: 12),
          Text(widget.message, textAlign: TextAlign.center),
        ],
      ),
    );
    return widget.scrollable
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [body],
          )
        : body;
  }
}
