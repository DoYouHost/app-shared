import 'package:flutter/material.dart';

import 'dash_tokens.dart';

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
  TextStyle get displayLg => _ui(26, FontWeight.w700, textPrimary);
  TextStyle get display => _ui(20, FontWeight.w800, textPrimary);

  TextStyle get titleLg => _ui(18, FontWeight.w800, textPrimary);
  TextStyle get titleMd => _ui(16, FontWeight.w700, textPrimary);
  TextStyle get titleSm => _ui(14, FontWeight.w700, textPrimary);

  /// The default for anything a user reads rather than scans.
  TextStyle get bodyStrong => _ui(14, FontWeight.w600, textPrimary);
  TextStyle get body => _ui(13, FontWeight.w600, textPrimary);

  /// Section headings inside a card — bold, but not a title.
  TextStyle get bodyBold => _ui(13, FontWeight.w700, textSecondary);
  TextStyle get bodySoft => _ui(13, FontWeight.w500, textSecondary);
  TextStyle get bodyPlain => _ui(13, FontWeight.w400, textSecondary);

  TextStyle get label => _ui(12, FontWeight.w600, textTertiary);
  TextStyle get labelSoft => _ui(12, FontWeight.w400, textTertiary);
  TextStyle get micro => _ui(11, FontWeight.w600, textTertiary);
  TextStyle get microSoft => _ui(11, FontWeight.w400, textTertiary);

  // Monospace: numbers that must not shift width as they tick.
  TextStyle get monoDisplay => _mono(26, FontWeight.w700, textPrimary);
  TextStyle get monoHeadline => _mono(18, FontWeight.w700, textPrimary);
  TextStyle get monoTitle => _mono(16, FontWeight.w800, textPrimary);
  TextStyle get monoValue => _mono(13, FontWeight.w600, textPrimary);
  TextStyle get monoLabel => _mono(11, FontWeight.w600, textTertiary);
  TextStyle get monoMicro => _mono(11, FontWeight.w400, textTertiary);

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
