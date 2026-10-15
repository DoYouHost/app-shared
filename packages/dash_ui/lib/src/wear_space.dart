import 'dash_space.dart';

/// The spacing of a Wear OS screen that Google names: Wear Material 3's button
/// inset (compose-material3 1.7.1 `ButtonDefaults`), off the 4 dp grid, and the
/// gaps of the Wear OS list guidance. A watch screen takes these roles from
/// here; spacing the guidance gives no role stays on [DashSpace]'s 4 dp grid,
/// which is what it asks for ("spacing is set in multiples of 4 dp").
abstract final class WearSpace {
  /// The content inset of every button variant, across and down
  /// (`ButtonDefaults.ContentPadding`).
  static const double buttonHorizontal = 14;
  static const double buttonVertical = 6;

  /// Between the elements of one group in a list.
  static const double inGroup = 4;

  /// Between groups within a slot of a list.
  static const double betweenGroups = 8;

  /// From a list's title to its content.
  static const double titleToContent = 12;

  /// Between the slots of a list, and between its top, middle and bottom
  /// sections.
  static const double betweenSections = 16;
}
