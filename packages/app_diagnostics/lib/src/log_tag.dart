import 'package:flutter/widgets.dart';

/// Names a control for the diagnostic log; untagged, a tap on it records only
/// `role=button`.
///
/// The log records identifiers and **never** accessibility labels: a label is
/// user-facing text — a printer name, a vehicle, a note — and the log can end up
/// in a public, permanent issue.
///
/// Ids are dotted and stable: `area.thing`, lowercase, never localized, never
/// containing data (`garage.card`, not `garage.card.VW-Golf`). Repeated rows
/// share one id — which row it was is not what a bug report needs. They are
/// wire values: renaming one decorrelates every log already attached to an
/// issue.
///
/// The probe carries an identifier down to the node actually hit, so tagging a
/// card names taps anywhere inside it unless something deeper has its own tag.
///
/// [selected] marks a control that is one of a set and currently the chosen one
/// (a segment, a preset chip). It rides here rather than on a `Semantics` of
/// its own because the two have to land on the **same** node: a separate
/// wrapper annotates a different one, so the reader announces the state and the
/// log resolves the press somewhere else — or, as measured, the state reaches
/// nobody at all. Nothing about it is recorded; the probe reads [id] only.
///
/// [expanded] says the same thing for a control that opens something: a menu
/// anchor, a disclosure. It rides here for the same reason [selected] does.
Widget logTag(String id, Widget child, {bool? selected, bool? expanded}) =>
    Semantics(
      identifier: id,
      selected: selected,
      expanded: expanded,
      child: child,
    );

/// Names a whole area of the app **and** everything inside it: the taps (via
/// [logTag]) and the code (via [LogSurface.of]).
///
/// This is the hierarchical unit — a screen, a tab, a sheet. One wrap names
/// every control underneath that does not name itself, and lets shared widgets
/// like the error and empty views say which screen they are standing on without
/// every call site passing it down by hand.
Widget logSurface(String id, Widget child) =>
    LogSurface(id, child: logTag(id, child));

/// The nearest enclosing [logSurface] name, for code that has a context but no
/// idea where it is being used.
class LogSurface extends InheritedWidget {
  const LogSurface(this.id, {required super.child, super.key});

  final String id;

  /// Read without registering a dependency, so it is usable from `initState` —
  /// which is where a one-shot record belongs, a rebuild being no news.
  static String? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LogSurface>()?.id;

  @override
  bool updateShouldNotify(LogSurface oldWidget) => oldWidget.id != id;
}

extension LogTagged on Widget {
  /// Postfix [logTag], for long expressions where wrapping would re-indent.
  Widget tagged(String id, {bool? selected, bool? expanded}) =>
      logTag(id, this, selected: selected, expanded: expanded);

  /// Postfix form of [logSurface].
  Widget surface(String id) => logSurface(id, this);
}
