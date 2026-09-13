import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dash_brand.dart';
import 'dash_tokens.dart';

/// One requirement a brand fails in one theme.
@immutable
class DashContrastIssue {
  const DashContrastIssue(this.brightness, this.token, this.problem);

  final Brightness brightness;
  final String token;
  final String problem;

  @override
  String toString() => '${brightness.name}: $token $problem';
}

/// Everything [brand] breaks in either theme; empty when it passes.
///
/// A colour cannot fail a widget test on its own, so this is the check an
/// application runs on its brand: `expect(dashContrastAudit(brand), isEmpty)`.
/// It holds:
///
/// * every ink that carries small text — the two muted inks, [DashTokens.accentInk]
///   and [DashTokens.accentOrangeInk] — at WCAG AA's 4.5:1 on the worst surface
///   the theme can put behind it;
/// * [DashTokens.onAccent] at 4.5:1 on the accent fill, since a button label
///   is text;
/// * each ink within 8° of the hue of the fill it darkens — contrast measures
///   lightness alone, and an amber darkened far enough reads as brown;
/// * the three text inks as a visible hierarchy.
List<DashContrastIssue> dashContrastAudit(DashBrand brand) => [
  for (final brightness in Brightness.values)
    ..._audit(DashTokens.resolve(brightness, brand)),
];

List<DashContrastIssue> _audit(DashTokens t) {
  final issues = <DashContrastIssue>[];
  void fail(String token, String problem) =>
      issues.add(DashContrastIssue(t.brightness, token, problem));

  final surfaces = _surfacesOf(t);
  for (final (token, ink) in [
    ('textSecondary', t.textSecondary),
    ('textTertiary', t.textTertiary),
    ('accentInk', t.accentInk),
    ('accentOrangeInk', t.accentOrangeInk),
  ]) {
    final (ratio, surface) = _worst(ink, surfaces);
    if (ratio < _smallText) {
      fail(token, 'is ${ratio.toStringAsFixed(2)}:1 over ${_hex(surface)}');
    }
  }

  final onFill = _ratio(_over(t.onAccent, t.accent), t.accent);
  if (onFill < _smallText) {
    fail('onAccent', 'is ${onFill.toStringAsFixed(2)}:1 on the accent fill');
  }

  for (final (token, fill, ink) in [
    ('accentInk', t.accent, t.accentInk),
    ('accentOrangeInk', t.accentOrange, t.accentOrangeInk),
  ]) {
    final drift = _hueDistance(fill, ink);
    if (drift >= _maxHueDrift) {
      fail(token, 'drifted ${drift.round()}° from the hue of its fill');
    }
  }

  final ground = surfaces.first;
  final tertiary = _ratio(_over(t.textTertiary, ground), ground);
  final secondary = _ratio(_over(t.textSecondary, ground), ground);
  final primary = _ratio(_over(t.textPrimary, ground), ground);
  if (!(tertiary < secondary && secondary < primary)) {
    fail(
      'textTertiary/textSecondary/textPrimary',
      'are not in rising contrast',
    );
  }

  return issues;
}

const _smallText = 4.5;
const _maxHueDrift = 8.0;

/// Every surface a theme can put behind small text: each stop of the
/// background gradient and the overlay surface, each bare, under a sub-card,
/// under a card, and under a sub-card on a card.
///
/// All of them rather than a guess at the worst, because the guess flips with
/// brightness: a light ink suffers most on the palest surface, a dark ink on
/// the bare background corner, where the white card flatters it.
List<Color> _surfacesOf(DashTokens t) {
  final card = t.cardGradient.colors.first;
  return [
    for (final ground in [
      ...t.backgroundGradient.colors,
      t.overlaySurface,
    ]) ...[
      ground,
      _over(t.subCard, ground),
      _over(card, ground),
      _over(t.subCard, _over(card, ground)),
    ],
  ];
}

(double, Color) _worst(Color ink, List<Color> surfaces) {
  var worst = (double.infinity, surfaces.first);
  for (final surface in surfaces) {
    final ratio = _ratio(_over(ink, surface), surface);
    if (ratio < worst.$1) worst = (ratio, surface);
  }
  return worst;
}

/// [top] composited over an opaque [bottom].
Color _over(Color top, Color bottom) => Color.from(
  alpha: 1,
  red: top.a * top.r + (1 - top.a) * bottom.r,
  green: top.a * top.g + (1 - top.a) * bottom.g,
  blue: top.a * top.b + (1 - top.a) * bottom.b,
);

/// WCAG 2.1 contrast ratio of two opaque colours.
double _ratio(Color a, Color b) {
  final (x, y) = (_luminance(a), _luminance(b));
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Around the colour wheel, so 358° and 2° are 4° apart.
double _hueDistance(Color a, Color b) {
  final d = (HSLColor.fromColor(a).hue - HSLColor.fromColor(b).hue).abs();
  return math.min(d, 360 - d);
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
