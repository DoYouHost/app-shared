import 'package:flutter/material.dart';

import 'dash_brand.dart';

/// The colour tokens of one theme: a near-black (or near-white) gradient ground
/// with layered translucent cards, three text inks, the brand accent and the
/// shared secondary accents.
///
/// Layout, type and radii are the same in both brightnesses; only colours
/// differ. Everything but the accent is fixed by [brightness], which is why
/// equality is [brightness] and [brand] alone.
@immutable
class DashTokens extends ThemeExtension<DashTokens> {
  const DashTokens.dark(this.brand)
    : brightness = Brightness.dark,
      backgroundGradient = const RadialGradient(
        center: Alignment(-0.6, -1),
        radius: 1.4,
        colors: [Color(0xFF131A12), Color(0xFF07090A), Color(0xFF050605)],
        stops: [0.0, 0.55, 1.0],
      ),
      cardGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x0DFFFFFF), Color(0x04FFFFFF)],
      ),
      cardBorder = const Color(0x12FFFFFF),
      subCard = const Color(0x08FFFFFF),
      subCardBorder = const Color(0x0DFFFFFF),
      groupCard = const Color(0x06FFFFFF),
      groupCardBorder = const Color(0x0FFFFFFF),
      textPrimary = const Color(0xFFFBFCF9),
      textSecondary = const Color(0xB0F2F4EF),
      textTertiary = const Color(0x88F2F4EF),
      accentOrange = const Color(0xFFFF9F5C),
      accentOrangeInk = const Color(0xFFFF9F5C),
      accentBlue = const Color(0xFF4FA6F7),
      danger = const Color(0xFFFF6B6B),
      dangerInk = const Color(0xFFFF6B6B),
      warning = const Color(0xFFE0A800),
      warningInk = const Color(0xFFE0A800),
      onDanger = const Color(0xFF10130E),
      gaugeTrack = const Color(0x10FFFFFF),
      hairline = const Color(0x14FFFFFF),
      dottedRule = const Color(0x24FFFFFF),
      navBar = const Color(0x59000000),
      overlaySurface = const Color(0xFF0E1310),
      overlayBorder = const Color(0x24FFFFFF);

  const DashTokens.light(this.brand)
    : brightness = Brightness.light,
      backgroundGradient = const RadialGradient(
        center: Alignment(-0.6, -1),
        radius: 1.4,
        colors: [Color(0xFFEAF2E7), Color(0xFFF6F8F4), Color(0xFFFDFEFC)],
        stops: [0.0, 0.55, 1.0],
      ),
      cardGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF5F7F3)],
      ),
      cardBorder = const Color(0x14000000),
      subCard = const Color(0x05000000),
      subCardBorder = const Color(0x0F000000),
      groupCard = const Color(0x04000000),
      groupCardBorder = const Color(0x12000000),
      textPrimary = const Color(0xFF10130E),
      textSecondary = const Color(0xC4202318),
      textTertiary = const Color(0xAC202318),
      accentOrange = const Color(0xFFE07C36),
      accentOrangeInk = const Color(0xFFA05019),
      accentBlue = const Color(0xFF2C7FE0),
      danger = const Color(0xFFD64545),
      dangerInk = const Color(0xFFBE2A2A),
      warning = const Color(0xFFE0A800),
      warningInk = const Color(0xFF7F5F00),
      onDanger = const Color(0xFFFFFFFF),
      gaugeTrack = const Color(0x14000000),
      hairline = const Color(0x14000000),
      dottedRule = const Color(0x1F000000),
      navBar = const Color(0x0A000000),
      overlaySurface = const Color(0xFFF6F8F4),
      overlayBorder = const Color(0x14000000);

  factory DashTokens.resolve(Brightness brightness, DashBrand brand) =>
      brightness == Brightness.dark
      ? DashTokens.dark(brand)
      : DashTokens.light(brand);

  /// The tokens registered by `buildDashThemeData`, or — under a theme that did
  /// not register any — tokens for its brightness with the accent taken from its
  /// colour scheme.
  static DashTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<DashTokens>() ??
        DashTokens.resolve(
          theme.brightness,
          DashBrand.fromScheme(theme.colorScheme),
        );
  }

  static const String fontUi = 'Manrope';
  static const String fontMono = 'JetBrainsMono';

  final Brightness brightness;
  final DashBrand brand;

  /// Full-screen backdrop behind the card list.
  final Gradient backgroundGradient;

  final Gradient cardGradient;
  final Color cardBorder;

  /// Small tiles inside a card, and form fields.
  final Color subCard;
  final Color subCardBorder;

  /// A grouping container inside a card.
  final Color groupCard;
  final Color groupCardBorder;

  final Color textPrimary;

  /// The two muted inks carry ordinary 11-12 px text, so both owe WCAG AA's
  /// 4.5:1 against the worst surface a theme can put behind them.
  /// [dashContrastAudit] measures that from these values; at the 0x66 alpha
  /// they once shared, the caption on a light card measured 2.4:1.
  final Color textSecondary;
  final Color textTertiary;

  /// The warm accent as a fill (a gauge, a chart slice) and as ink (a caveat's
  /// mark, a "paused" label). The vivid swatch reads 2.7:1 on the palest light
  /// card — under even the 3:1 a meaningful mark needs.
  final Color accentOrange;
  final Color accentOrangeInk;

  final Color accentBlue;

  /// Warning, low, error, delete — as a fill, a border or a dot.
  final Color danger;

  /// The same red as text or an icon. The fill reads 3.7:1 on the light
  /// background, which is under what a word owes, and an error message is the
  /// one sentence a user most needs to read.
  final Color dangerInk;

  /// The label on a solid red fill, which is [dangerInk] rather than [danger]:
  /// neither white nor a dark ink reaches 4.5:1 on the lighter red. See
  /// `dashDangerButtonStyle`.
  final Color onDanger;

  /// A check that passed with reservations — between the accent's "fine" and
  /// [danger]'s "failed" — as a fill or a mark.
  final Color warning;

  /// The same yellow as text or an icon: the swatch reads 1.8:1 on the light
  /// background, where even an icon owes 3:1.
  final Color warningInk;

  /// Background track of a gauge or progress bar.
  final Color gaugeTrack;

  final Color hairline;

  /// Dotted separators between list rows.
  final Color dottedRule;

  final Color navBar;

  /// Opaque fill for dialogs, menus, snackbars and sheets. The card tokens are
  /// translucent washes meant for [backgroundGradient]; an overlay floats over
  /// an arbitrary route and needs a solid ground to stay legible.
  final Color overlaySurface;
  final Color overlayBorder;

  /// The brand accent as a fill — gauges, dots, ON states, the primary button.
  Color get accent => brand.of(brightness).fill;

  /// The brand accent as text or an icon, and `colorScheme.primary`: every
  /// `TextButton` is painted with it. Never a fill.
  Color get accentInk => brand.of(brightness).ink;

  /// Text and icons on a solid [accent] fill.
  Color get onAccent => brand.onAccent;

  bool get isDark => brightness == Brightness.dark;

  @override
  DashTokens copyWith({Brightness? brightness, DashBrand? brand}) =>
      DashTokens.resolve(brightness ?? this.brightness, brand ?? this.brand);

  /// Snaps rather than blends: `ThemeData.lerp` flips `brightness` at the
  /// midpoint, and tokens that interpolated would spend half of a theme change
  /// reporting one brightness while painting the other.
  @override
  DashTokens lerp(covariant ThemeExtension<DashTokens>? other, double t) =>
      other is DashTokens && t >= 0.5 ? other : this;

  @override
  bool operator ==(Object other) =>
      other is DashTokens &&
      other.brightness == brightness &&
      other.brand == brand;

  @override
  int get hashCode => Object.hash(brightness, brand);
}
