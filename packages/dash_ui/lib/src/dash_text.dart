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
      _ui(DashFontSize.hero, FontWeight.w700, textPrimary);
  TextStyle get display =>
      _ui(DashFontSize.display, FontWeight.w800, textPrimary);

  TextStyle get titleLg =>
      _ui(DashFontSize.heading, FontWeight.w800, textPrimary);
  TextStyle get titleMd => _ui(DashFontSize.lead, FontWeight.w700, textPrimary);
  TextStyle get titleSm =>
      _ui(DashFontSize.title, FontWeight.w700, textPrimary);

  /// The default for anything a user reads rather than scans.
  TextStyle get bodyStrong =>
      _ui(DashFontSize.title, FontWeight.w600, textPrimary);
  TextStyle get body => _ui(DashFontSize.body, FontWeight.w600, textPrimary);

  /// Section headings inside a card — bold, but not a title.
  TextStyle get bodyBold =>
      _ui(DashFontSize.body, FontWeight.w700, textSecondary);
  TextStyle get bodySoft =>
      _ui(DashFontSize.body, FontWeight.w500, textSecondary);
  TextStyle get bodyPlain =>
      _ui(DashFontSize.body, FontWeight.w400, textSecondary);

  TextStyle get label => _ui(DashFontSize.label, FontWeight.w600, textTertiary);
  TextStyle get labelSoft =>
      _ui(DashFontSize.label, FontWeight.w400, textTertiary);
  TextStyle get micro => _ui(DashFontSize.micro, FontWeight.w600, textTertiary);
  TextStyle get microSoft =>
      _ui(DashFontSize.micro, FontWeight.w400, textTertiary);

  // Monospace: numbers that must not shift width as they tick.
  TextStyle get monoDisplay =>
      _mono(DashFontSize.hero, FontWeight.w700, textPrimary);
  TextStyle get monoHeadline =>
      _mono(DashFontSize.heading, FontWeight.w700, textPrimary);
  TextStyle get monoTitle =>
      _mono(DashFontSize.lead, FontWeight.w800, textPrimary);
  TextStyle get monoValue =>
      _mono(DashFontSize.body, FontWeight.w600, textPrimary);
  TextStyle get monoLabel =>
      _mono(DashFontSize.micro, FontWeight.w600, textTertiary);
  TextStyle get monoMicro =>
      _mono(DashFontSize.micro, FontWeight.w400, textTertiary);

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
