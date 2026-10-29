/// The font sizes of a watch screen, on a 2 sp grid: every `fontSize` on the watch
/// is one of these, and [WearText] names the role each plays.
///
/// 12 sp is Play's floor for essential text on Wear OS (WO-V14); only [fine] may
/// go below it, 10 sp being the least WO-V14 allows for non-essential text. A
/// quieter line is quieter by colour, never by size.
abstract final class WearFontSize {
  /// Non-essential fine print: a label above a value, a field's hint.
  static const double fine = 10;

  /// Ordinary prose and readouts.
  static const double body = 12;

  /// The header of a screen, a step heading, the name of a row, a typed value, a
  /// button's second line.
  static const double title = 14;

  /// The question of a full-screen confirm and the label of a button.
  static const double hero = 16;
}
