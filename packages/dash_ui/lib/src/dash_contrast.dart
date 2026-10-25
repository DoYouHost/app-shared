import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import 'dash_brand.dart';
import 'dash_tokens.dart';

part 'dash_brand_from_scheme.dart';

/// One requirement a brand fails in one theme.
@immutable
class DashContrastIssue {
  const DashContrastIssue(this.brightness, this.token, this.problem);

  final Brightness brightness;
  final String token;
  final String problem;

  @override
  bool operator ==(Object other) =>
      other is DashContrastIssue &&
      other.brightness == brightness &&
      other.token == token &&
      other.problem == problem;

  @override
  int get hashCode => Object.hash(brightness, token, problem);

  @override
  String toString() => '${brightness.name}: $token $problem';
}

/// Everything the two themes built from [brand] break; empty when both pass.
///
/// A colour cannot fail a widget test on its own, so this is the check an
/// application runs on its brand: `expect(dashContrastAudit(brand), isEmpty)`.
///
/// The fixed palette is measured too, although no brand can change it: this
/// package's tests already hold it, so in an app it can only fail after a
/// dash_ui upgrade — and that is the upgrade worth stopping. It holds:
///
/// * every ink that carries small text — the two muted inks, [DashTokens.accentInk],
///   [DashTokens.accentOrangeInk], [DashTokens.dangerInk] and
///   [DashTokens.warningInk] — at WCAG AA's
///   4.5:1 on the worst surface the theme can put behind it;
/// * [DashTokens.onAccent] on the accent fill and [DashTokens.onDanger] on the
///   red one at 4.5:1, since a button label is text;
/// * each ink within 8° of the HCT hue of the fill it darkens — contrast
///   measures lightness alone, and an amber darkened far enough reads as brown;
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
    ('dangerInk', t.dangerInk),
    ('warningInk', t.warningInk),
  ]) {
    final (ratio, surface) = _worst(ink, surfaces);
    if (ratio < _smallText) {
      fail(token, 'is ${ratio.toStringAsFixed(2)}:1 over ${_hex(surface)}');
    }
  }

  for (final (token, label, fill) in [
    ('onAccent', t.onAccent, t.accent),
    ('onDanger', t.onDanger, t.dangerInk),
  ]) {
    final onFill = _ratio(_over(label, fill), fill);
    if (onFill < _smallText) {
      fail(token, 'is ${onFill.toStringAsFixed(2)}:1 on its fill');
    }
  }

  for (final (token, fill, ink) in [
    ('accentInk', t.accent, t.accentInk),
    ('accentOrangeInk', t.accentOrange, t.accentOrangeInk),
    ('dangerInk', t.danger, t.dangerInk),
    ('warningInk', t.warning, t.warningInk),
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

/// The worst contrast [ink] reaches on any surface [t] can put behind text,
/// for an application's own colour that no token covers.
double dashWorstContrast(Color ink, DashTokens t) =>
    _worst(ink, _surfacesOf(t)).$1;

/// The body of [DashBrand.fromSchemes], here for the private contrast
/// helpers; `dash_ui.dart` hides it from the package's API.
DashBrand brandFromSchemes({
  required ColorScheme light,
  required ColorScheme dark,
}) => _brandFromSchemes(light, dark);

const _smallText = 4.5;
const _maxHueDrift = 8.0;

/// Every surface a theme can put behind small text: each stop of the
/// background gradient, the overlay surface and the scaffold, each bare, under a sub-card,
/// under either end of a card, and under a sub-card on a card.
///
/// All of them rather than a guess at the worst, because the guess flips with
/// brightness: a light ink suffers most on the palest surface, a dark ink on
/// the bare background corner, where the white card flatters it. Both card
/// ends, because a brand's own surfaces can make the far end the darker one.
List<Color> _surfacesOf(DashTokens t) {
  final cardEnds = t.cardGradient.colors;
  return [
    for (final ground in [
      ...t.backgroundGradient.colors,
      t.overlaySurface,
      t.scaffold,
    ]) ...[
      ground,
      _over(t.subCard, ground),
      for (final card in [cardEnds.first, cardEnds.last]) ...[
        _over(card, ground),
        _over(t.subCard, _over(card, ground)),
      ],
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

/// Around the colour wheel, so 358° and 2° are 4° apart. HCT hue, the one
/// Material keeps constant along a tonal palette; HSL hue is not perceptual,
/// so an ink darkened at a fixed HSL hue can still look like another colour.
///
/// Zero when either colour is under Material's own chroma cutoff for a hue
/// worth theming with (`Score._cutoffChroma` in material_color_utilities):
/// there an 8-bit rounding moves the hue by tens of degrees nobody can see.
double _hueDistance(Color a, Color b) {
  final (ha, hb) = (Hct.fromInt(a.toARGB32()), Hct.fromInt(b.toARGB32()));
  if (ha.chroma < _hueChromaCutoff || hb.chroma < _hueChromaCutoff) return 0;
  final d = (ha.hue - hb.hue).abs();
  return math.min(d, 360 - d);
}

const _hueChromaCutoff = 5.0;

bool _isGrey(Color c) => c.r == c.g && c.g == c.b;

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
