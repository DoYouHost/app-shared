part of 'dash_contrast.dart';

/// The brand [DashBrand.fromSchemes] builds from a Material scheme pair.
///
/// Material's way throughout: the accent is tones of one HCT tonal palette, the
/// hue and chroma of `light.primary`, and the light ink is the tone
/// `Contrast.darker` gives for 4.5:1 on the darkest surface it can sit on. The grounds come
/// from the schemes' container roles, never `surface`: the dynamic_color plugin
/// takes `surface` from the device's neutral palette and the containers from
/// `fromSeed(primary)`, and mixing the two would put two palettes into one
/// gradient.
DashBrand _brandFromSchemes(ColorScheme light, ColorScheme dark) {
  final darkSurfaces = DashSurfaces(
    glow: dark.surfaceContainerLow,
    middle: dark.surfaceContainerLowest,
    edge: Color.lerp(dark.surfaceContainerLowest, Colors.black, 0.35)!,
    // A white wash: the card's far end carries no tint of its own.
    cardEnd: DashSurfaces.classicDark.cardEnd,
    overlay: dark.surfaceContainerLow,
    scaffold: dark.surfaceContainerLowest,
  );
  final lightSurfaces = DashSurfaces(
    glow: light.surfaceContainer,
    middle: light.surfaceContainerLow,
    edge: light.surfaceContainerLowest,
    cardEnd: light.surfaceContainerLow,
    overlay: light.surfaceContainerLow,
    scaffold: light.surfaceContainerLowest,
  );

  // Material makes a monochrome scheme a variant, not something read off a
  // colour; its primary is an exact grey, which is the one signal a scheme
  // carries. An 8-bit grey reads back from HCT with a little chroma and an
  // arbitrary hue, so it gets the zero-chroma palette instead.
  final source = Hct.fromInt(light.primary.toARGB32());
  final palette = _isGrey(light.primary)
      ? TonalPalette.of(0, 0)
      : TonalPalette.of(source.hue, source.chroma);
  Color tone(double t) =>
      Color(Hct.from(palette.hue, palette.chroma, t).toInt());

  final darkAccent = tone(80);
  final lightFill = tone(60);
  final onAccent = [tone(10), Colors.black].firstWhere(
    (ink) =>
        _ratio(ink, darkAccent) >= _smallText &&
        _ratio(ink, lightFill) >= _smallText,
    orElse: () => Colors.black,
  );

  final probe = DashTokens.light(
    DashBrand(
      dark: DashAccent(fill: darkAccent, ink: darkAccent),
      light: DashAccent(fill: lightFill, ink: lightFill),
      onAccent: onAccent,
      lightSurfaces: lightSurfaces,
    ),
  );
  // A dark ink fares worst on the darkest surface it can sit on, its own
  // accent wash included.
  final darkest = _accentSurfacesOf(
    probe,
  ).map((s) => ColorUtils.lstarFromArgb(s.toARGB32())).reduce(math.min);
  // Black when no tone reaches the ratio, as MCU's own fallback has it.
  var inkTone = Contrast.darkerUnsafe(tone: darkest, ratio: _smallText);
  // The tone is continuous and the ink is 8-bit; rounding can land a hair
  // under the ratio the audit then measures on the rounded colour.
  while (inkTone > 0 &&
      _worst(tone(inkTone), _accentSurfacesOf(probe)).$1 < _smallText) {
    inkTone = math.max(0, inkTone - 0.5);
  }

  return DashBrand(
    dark: DashAccent(fill: darkAccent, ink: darkAccent),
    light: DashAccent(fill: lightFill, ink: tone(inkTone)),
    onAccent: onAccent,
    darkSurfaces: darkSurfaces,
    lightSurfaces: lightSurfaces,
  );
}
