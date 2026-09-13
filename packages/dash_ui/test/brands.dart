import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/painting.dart';

/// The two brands this package was extracted for, copied so the audit is run
/// here on real accents and not only on invented ones. The applications keep
/// the authoritative values and run the audit on those themselves.
const green = DashBrand(
  dark: DashAccent(fill: Color(0xFF5FE08A), ink: Color(0xFF5FE08A)),
  light: DashAccent(fill: Color(0xFF34C46E), ink: Color(0xFF18733D)),
  onAccent: Color(0xFF0A0C08),
);

const gold = DashBrand(
  dark: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFFD9A021)),
  light: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFF835E0F)),
  onAccent: Color(0xFF1A1206),
);
