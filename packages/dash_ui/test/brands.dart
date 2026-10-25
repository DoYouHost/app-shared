import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/painting.dart';

/// The two brands this package was extracted for, copied so the audit is run
/// here on real accents and not only on invented ones. The applications keep
/// the authoritative values and run the audit on those themselves. The inks are
/// the nearest HCT tones that clear the accent's own wash (v0.14.2); an app
/// still on the older inks fails its own audit on upgrade, which is the point.
const green = DashBrand(
  dark: DashAccent(fill: Color(0xFF5FE08A), ink: Color(0xFF5FE08A)),
  light: DashAccent(fill: Color(0xFF34C46E), ink: Color(0xFF15713B)),
  onAccent: Color(0xFF0A0C08),
);

const gold = DashBrand(
  dark: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFFDCA324)),
  light: DashAccent(fill: Color(0xFFD9A021), ink: Color(0xFF815C0D)),
  onAccent: Color(0xFF1A1206),
);
