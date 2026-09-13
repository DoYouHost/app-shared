import 'package:flutter/widgets.dart';

/// How wide [text] would be on one line in [style], in the reading direction and
/// at the system font size it will actually be painted with.
///
/// Every layout that asks — a button deciding whether its label fits beside
/// another one, a row of stats deciding how many fit across — had its own copy,
/// and what is worth sharing is the part none may forget: the ambient
/// [TextScaler], because a label measured at 1.0 and painted at 1.3 decides
/// wrongly at exactly the font size where the decision matters, and the
/// [Directionality] the paragraph is laid out in.
///
/// [style] stays the caller's business. Only the caller knows which style its
/// widget will paint with, and that has to be the one measured.
double textWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  return painter.width;
}
