import 'package:material_ui/material_ui.dart';

import 'dash_tokens.dart';

import 'dash_scale.dart';

/// Full-screen gradient backdrop. Wrap a transparent [Scaffold] in it so the
/// gradient shows through the app bar and the body.
class DashBackground extends StatelessWidget {
  const DashBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DashTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: t.backgroundGradient),
      child: child,
    );
  }
}

/// Transparent app bar with the design's bold, tightly tracked title, for use
/// inside a [DashBackground] and a transparent [Scaffold].
///
/// [titleWidget] replaces the text title when given — a wordmark, say.
AppBar dashAppBar(
  BuildContext context, {
  String? title,
  Widget? titleWidget,
  List<Widget>? actions,
  Widget? leading,
  PreferredSizeWidget? bottom,
  bool automaticallyImplyLeading = true,
}) {
  final t = DashTokens.of(context);
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: leading,
    iconTheme: IconThemeData(color: t.textPrimary),
    title:
        titleWidget ??
        Text(
          title ?? '',
          style: TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: DashFontSize.hero,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: t.textPrimary,
          ),
        ),
    actions: actions,
    bottom: bottom,
  );
}

/// Small rounded status pill, tinted with an accent.
class DashPill extends StatelessWidget {
  const DashPill({
    super.key,
    required this.label,
    required this.accent,
    this.accentInk,
    this.leadingDot = false,
    this.icon,
    this.dense = false,
  });

  final String label;

  /// The swatch the pill is filled and outlined with, at low alpha.
  final Color accent;

  /// The swatch its label and icon are painted with. Defaults to [accent],
  /// which is wrong for the vivid swatches — pass the matching `…Ink` token.
  final Color? accentInk;

  final bool leadingDot;
  final IconData? icon;

  /// A marker crowded in beside a title or wrapped several to a row, rather
  /// than a badge standing on its own.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ink = accentInk ?? accent;
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: DashAlpha.wash),
        borderRadius: BorderRadius.circular(DashRadius.xl),
        border: Border.all(color: accent.withValues(alpha: DashAlpha.outline)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: DashIcon.xs, color: ink),
            SizedBox(width: dense ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: DashTokens.fontUi,
              fontSize: dense ? DashFontSize.micro : DashFontSize.label,
              fontWeight: dense ? FontWeight.w600 : FontWeight.w700,
              letterSpacing: dense ? 0 : 0.3,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Field chrome for form screens: a rounded [DashTokens.subCard] fill with a
/// hairline border that turns to the accent on focus.
InputDecoration dashFieldDecoration(
  DashTokens t, {
  String? labelText,
  String? hintText,
  String? helperText,
  String? errorText,
  String? suffixText,
  Widget? suffixIcon,
  Widget? prefixIcon,
}) {
  final radius = BorderRadius.circular(DashRadius.lg);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    isDense: true,
    // Dense alone draws a 45 dp field; 48 dp is Android's touch-target floor.
    constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
    filled: true,
    fillColor: t.subCard,
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
    labelStyle: TextStyle(
      fontFamily: DashTokens.fontUi,
      fontSize: DashFontSize.body,
      fontWeight: FontWeight.w600,
      color: t.textSecondary,
    ),
    floatingLabelStyle: TextStyle(
      fontFamily: DashTokens.fontUi,
      fontSize: DashFontSize.body,
      fontWeight: FontWeight.w600,
      color: t.accentInk,
    ),
    hintStyle: TextStyle(fontFamily: DashTokens.fontUi, color: t.textTertiary),
    helperStyle: TextStyle(
      fontFamily: DashTokens.fontUi,
      fontSize: DashFontSize.micro,
      color: t.textTertiary,
    ),
    suffixStyle: TextStyle(
      fontFamily: DashTokens.fontMono,
      fontSize: DashFontSize.label,
      color: t.textTertiary,
    ),
    border: border(t.subCardBorder),
    enabledBorder: border(t.subCardBorder),
    focusedBorder: border(t.accent, 1.5),
    errorBorder: border(t.danger),
    focusedErrorBorder: border(t.danger, 1.5),
  );
}

/// The primary call to action: a solid accent fill with [DashTokens.onAccent]
/// ink.
ButtonStyle dashPrimaryButtonStyle(DashTokens t) => FilledButton.styleFrom(
  backgroundColor: t.accent,
  foregroundColor: t.onAccent,
  disabledBackgroundColor: t.accent.withValues(alpha: DashAlpha.soft),
  disabledForegroundColor: t.onAccent.withValues(alpha: DashAlpha.scrim),
  textStyle: const TextStyle(
    fontFamily: DashTokens.fontUi,
    fontSize: DashFontSize.title,
    fontWeight: FontWeight.w700,
  ),
  // The horizontal padding is for auto-width buttons such as dialog actions; a
  // full-width button centres its label regardless.
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(DashRadius.lg),
  ),
);

/// A call to action that destroys something: [dashPrimaryButtonStyle] in red,
/// with the fill and the label both chosen to read.
/// The answer that backs out: [dashPrimaryButtonStyle]'s shape and padding, so
/// it stands the same height as the button beside it, on a quiet fill of the
/// text colour.
ButtonStyle dashNeutralButtonStyle(DashTokens t) =>
    dashPrimaryButtonStyle(t).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => t.textPrimary.withValues(
          alpha: states.contains(WidgetState.disabled)
              ? DashAlpha.faint
              : DashAlpha.faint,
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? t.textTertiary
            : t.textPrimary,
      ),
      overlayColor: WidgetStatePropertyAll(
        t.textPrimary.withValues(alpha: DashAlpha.faint),
      ),
    );

ButtonStyle dashDangerButtonStyle(DashTokens t) =>
    dashPrimaryButtonStyle(t).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? t.dangerInk.withValues(alpha: DashAlpha.soft)
            : t.dangerInk,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? t.onDanger.withValues(alpha: DashAlpha.scrim)
            : t.onDanger,
      ),
    );
