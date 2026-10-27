import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dash_ui/dash_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A segment for [DashSegToggle].
typedef DashSegment<T> = ({T value, String label, IconData? icon});

/// Horizontal pill toggle (Specific/Any, Inherit/On/Off, Now/Later).
/// The selected segment wears the accent fill; the rest are neutral.
class DashSegToggle<T> extends StatelessWidget {
  const DashSegToggle({
    super.key,
    required this.id,
    required this.selected,
    required this.segments,
    required this.onChanged,
  });

  /// Log identifier, required from the call site: several toggles on one screen
  /// set different things, and one tag written into `build` would make a report
  /// say only that "a segment" was pressed.
  final String id;

  final T selected;
  final List<DashSegment<T>> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return Row(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: DashSpace.sm),
          Expanded(child: _segButton(t, segments[i])),
        ],
      ],
    );
  }

  Widget _segButton(DashTokens t, DashSegment<T> seg) {
    final isSel = seg.value == selected;
    return Material(
      color: isSel ? t.accent : t.groupCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(seg.value),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: DashSpace.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? Colors.transparent : t.groupCardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (seg.icon != null) ...[
                Icon(
                  seg.icon,
                  size: 16,
                  color: isSel ? t.onAccent : t.textSecondary,
                ),
                const SizedBox(width: DashSpace.sm),
              ],
              Flexible(
                child: Text(
                  seg.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyBold.copyWith(
                    color: isSel ? t.onAccent : t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // The fill is the only thing that says which segment is on.
      ).tagged(id, selected: isSel),
    );
  }
}
