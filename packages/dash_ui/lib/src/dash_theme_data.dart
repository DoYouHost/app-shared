import 'package:material_ui/material_ui.dart';

import 'dash_brand.dart';
import 'dash_tokens.dart';
import 'dash_widgets.dart';
import 'dash_scale.dart';
import 'dash_space.dart';

/// The application [ThemeData] for [brightness] and [brand].
///
/// Every stock Material widget — dialogs, menus, sheets, chips, snackbars,
/// switches — takes the design from here without a call site opting in, and
/// the resolved [DashTokens] are registered as a theme extension, which is
/// where [DashTokens.of] reads them.
ThemeData buildDashThemeData(
  Brightness brightness, {
  required DashBrand brand,
}) {
  final t = DashTokens.resolve(brightness, brand);

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: t.accent,
        brightness: brightness,
      ).copyWith(
        primary: t.accentInk,
        onPrimary: t.onAccent,
        secondary: t.accentBlue,
        // Material paints `errorText` and a destructive fill with these, so the
        // readable red and the label that reads on it.
        error: t.dangerInk,
        onError: t.onDanger,
        surface: t.overlaySurface,
        onSurface: t.textPrimary,
        surfaceContainerHighest: t.overlaySurface,
        surfaceContainerHigh: t.overlaySurface,
        surfaceContainer: t.overlaySurface,
        onSurfaceVariant: t.textSecondary,
        outline: t.subCardBorder,
        outlineVariant: t.hairline,
      );

  final baseText = ThemeData(brightness: brightness).textTheme.apply(
    fontFamily: DashTokens.fontUi,
    bodyColor: t.textPrimary,
    displayColor: t.textPrimary,
  );

  final radius16 = BorderRadius.circular(DashRadius.lg);
  final radius20 = BorderRadius.circular(DashRadius.xl);

  return ThemeData(
    useMaterial3: true,
    extensions: [t],
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: t.scaffold,
    textTheme: baseText,
    primaryTextTheme: baseText,
    iconTheme: IconThemeData(color: t.textSecondary, applyTextScaling: true),
    primaryIconTheme: IconThemeData(
      color: t.textPrimary,
      applyTextScaling: true,
    ),
    dividerTheme: DividerThemeData(color: t.hairline, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: t.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: t.textPrimary, applyTextScaling: true),
      titleTextStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.display,
        fontWeight: DashWeight.bold,
        color: t.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: t.overlaySurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius16),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.overlaySurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius20,
        side: BorderSide(color: t.overlayBorder),
      ),
      // The filled action button uses the heavy primary style (radius 16);
      // keep it clear of the dialog's rounded corner/border.
      actionsPadding: const EdgeInsets.fromLTRB(
        DashSpace.xl,
        DashSpace.sm,
        DashSpace.xl,
        DashSpace.xl,
      ),
      titleTextStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.heading,
        fontWeight: DashWeight.bold,
        color: t.textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.title,
        color: t.textSecondary,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: t.overlaySurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius16,
        side: BorderSide(color: t.overlayBorder),
      ),
      textStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.title,
        fontWeight: DashWeight.semibold,
        color: t.textPrimary,
      ),
      iconColor: t.textSecondary,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.overlaySurface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: t.overlaySurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DashRadius.xl),
        ),
        side: BorderSide(color: t.overlayBorder),
      ),
      dragHandleColor: t.textTertiary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.overlaySurface,
      contentTextStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.title,
        color: t.textPrimary,
      ),
      actionTextColor: t.accentInk,
      shape: RoundedRectangleBorder(
        borderRadius: radius16,
        side: BorderSide(color: t.overlayBorder),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.overlaySurface,
        borderRadius: radius16,
        border: Border.all(color: t.overlayBorder),
      ),
      textStyle: TextStyle(fontFamily: DashTokens.fontUi, color: t.textPrimary),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.textSecondary,
      textColor: t.textPrimary,
      titleTextStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.lead,
        fontWeight: DashWeight.semibold,
        color: t.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.body,
        color: t.textSecondary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.subCard,
      selectedColor: t.accent.withValues(alpha: DashAlpha.wash),
      disabledColor: t.subCard.withValues(alpha: DashAlpha.scrim),
      side: BorderSide(color: t.subCardBorder),
      shape: StadiumBorder(side: BorderSide(color: t.subCardBorder)),
      labelStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.body,
        fontWeight: DashWeight.semibold,
        color: t.textPrimary,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        fontSize: DashFontSize.body,
        fontWeight: DashWeight.semibold,
        color: t.accentInk,
      ),
      checkmarkColor: t.accentInk,
      iconTheme: IconThemeData(
        color: t.textSecondary,
        size: DashIcon.md,
        applyTextScaling: true,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DashSpace.md,
        vertical: DashSpace.sm,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.accent.withValues(alpha: DashAlpha.wash)
              : t.subCard,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? t.accentInk
              : t.textSecondary,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? t.accent.withValues(alpha: DashAlpha.outline)
                : t.subCardBorder,
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: DashTokens.fontUi,
            fontSize: DashFontSize.body,
            fontWeight: DashWeight.bold,
          ),
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? t.accent : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? t.accent.withValues(alpha: DashAlpha.outline)
            : t.subCard,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? t.accent : null,
      ),
      checkColor: WidgetStatePropertyAll(t.onAccent),
      // subCardBorder (~5% white) is invisible for an interactive control;
      // use the mid-contrast outline Material itself uses (onSurfaceVariant).
      side: BorderSide(color: t.textSecondary, width: DashStroke.regular),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? t.accent : t.textTertiary,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: t.accent,
      inactiveTrackColor: t.gaugeTrack,
      thumbColor: t.accent,
      overlayColor: t.accent.withValues(alpha: DashAlpha.wash),
      valueIndicatorColor: t.overlaySurface,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.accent,
      linearTrackColor: t.gaugeTrack,
      circularTrackColor: t.gaugeTrack,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(fontFamily: DashTokens.fontUi, color: t.textPrimary),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.overlaySurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: radius16,
            side: BorderSide(color: t.overlayBorder),
          ),
        ),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.overlaySurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: radius16,
            side: BorderSide(color: t.overlayBorder),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      filled: true,
      fillColor: t.subCard,
      labelStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        color: t.textSecondary,
      ),
      hintStyle: TextStyle(
        fontFamily: DashTokens.fontUi,
        color: t.textTertiary,
      ),
      border: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide(color: t.subCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide(color: t.subCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide(color: t.accent, width: DashStroke.regular),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide(color: t.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius16,
        borderSide: BorderSide(color: t.danger, width: DashStroke.regular),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: dashPrimaryButtonStyle(t)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: t.subCard,
        foregroundColor: t.textPrimary,
        textStyle: const TextStyle(
          fontFamily: DashTokens.fontUi,
          fontWeight: DashWeight.bold,
        ),
        // Match the filled button padding so heights line up when buttons of
        // different kinds sit side by side.
        padding: const EdgeInsets.symmetric(
          horizontal: DashSpace.lg,
          vertical: DashSpace.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.textPrimary,
        side: BorderSide(color: t.subCardBorder),
        textStyle: const TextStyle(
          fontFamily: DashTokens.fontUi,
          fontWeight: DashWeight.bold,
        ),
        // Match the filled button padding so heights line up when buttons of
        // different kinds sit side by side.
        padding: const EdgeInsets.symmetric(
          horizontal: DashSpace.lg,
          vertical: DashSpace.lg,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.accentInk,
        textStyle: const TextStyle(
          fontFamily: DashTokens.fontUi,
          fontWeight: DashWeight.bold,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius16),
      ),
    ),
    disabledColor: t.textTertiary,
    hintColor: t.textTertiary,
    splashColor: t.accent.withValues(alpha: DashAlpha.faint),
    highlightColor: t.accent.withValues(alpha: DashAlpha.faint),
  );
}
