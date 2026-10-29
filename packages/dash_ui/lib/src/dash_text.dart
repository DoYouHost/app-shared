import 'package:material_ui/material_ui.dart';

import 'dash_tokens.dart';

import 'dash_scale.dart';

/// The type scale, by role.
///
/// The roles were measured from bambuddy's screens, which had assembled 439
/// literal styles in 188 shapes: they are those shapes rounded onto eight UI
/// steps (11, 12, 13, 14, 16, 18, 20, 26) and five mono ones (11, 13, 16, 18,
/// 26), each with the ink it carried in most of its uses.
///
/// A role that needs another colour takes one — `t.body.copyWith(color:
/// t.danger)` — and that is the only part of a style a screen should decide. A
/// size or weight no role covers means the design grew a step, and the step
/// belongs here.
extension DashTextStyles on DashTokens {
  // Display: readouts meant to be read at a distance.
  TextStyle get displayLg =>
      _ui(DashFontSize.hero, DashWeight.bold, textPrimary);
  TextStyle get display =>
      _ui(DashFontSize.display, DashWeight.bold, textPrimary);

  TextStyle get titleLg =>
      _ui(DashFontSize.heading, DashWeight.bold, textPrimary);
  TextStyle get titleMd => _ui(DashFontSize.lead, DashWeight.bold, textPrimary);
  TextStyle get titleSm =>
      _ui(DashFontSize.title, DashWeight.bold, textPrimary);

  /// The default for anything a user reads rather than scans.
  TextStyle get bodyStrong =>
      _ui(DashFontSize.title, DashWeight.semibold, textPrimary);
  TextStyle get body =>
      _ui(DashFontSize.body, DashWeight.semibold, textPrimary);

  /// Section headings inside a card — bold, but not a title.
  TextStyle get bodyBold =>
      _ui(DashFontSize.body, DashWeight.bold, textSecondary);
  TextStyle get bodySoft =>
      _ui(DashFontSize.body, DashWeight.medium, textSecondary);
  TextStyle get bodyPlain =>
      _ui(DashFontSize.body, DashWeight.regular, textSecondary);

  TextStyle get label =>
      _ui(DashFontSize.label, DashWeight.semibold, textTertiary);
  TextStyle get labelSoft =>
      _ui(DashFontSize.label, DashWeight.regular, textTertiary);
  TextStyle get micro =>
      _ui(DashFontSize.micro, DashWeight.semibold, textTertiary);
  TextStyle get microSoft =>
      _ui(DashFontSize.micro, DashWeight.regular, textTertiary);

  // Monospace: numbers that must not shift width as they tick.
  TextStyle get monoDisplay =>
      _mono(DashFontSize.hero, DashWeight.bold, textPrimary);
  TextStyle get monoHeadline =>
      _mono(DashFontSize.heading, DashWeight.bold, textPrimary);
  TextStyle get monoTitle =>
      _mono(DashFontSize.lead, DashWeight.bold, textPrimary);
  TextStyle get monoValue =>
      _mono(DashFontSize.body, DashWeight.semibold, textPrimary);
  TextStyle get monoLabel =>
      _mono(DashFontSize.micro, DashWeight.semibold, textTertiary);
  TextStyle get monoMicro =>
      _mono(DashFontSize.micro, DashWeight.regular, textTertiary);

  TextStyle _ui(double size, FontWeight weight, Color color) => TextStyle(
    fontFamily: DashTokens.fontUi,
    fontSize: size,
    fontWeight: weight,
    color: color,
  );

  TextStyle _mono(double size, FontWeight weight, Color color) => TextStyle(
    fontFamily: DashTokens.fontMono,
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}
