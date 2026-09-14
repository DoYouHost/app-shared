import 'dart:math' as math;

import 'package:app_diagnostics/app_diagnostics.dart';
import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Asks before doing something. `true` only when the user confirms; the cancel
/// button, the barrier and back all answer `false`.
///
/// Both answers are filled buttons sharing the width equally: dismiss on the
/// left, confirm on the right. When a word of either label cannot fit its half
/// — a German compound, a large system font — they stack full-width instead,
/// dismiss above confirm, because the alternative is a word broken mid-way.
/// [destructive] paints the confirm in the danger red; otherwise it takes the
/// brand accent, for a question where nothing is lost either way.
///
/// [id] names the dialog in the log. The buttons are tagged `<id>.cancel` and
/// `<id>.confirm`, and the answer is recorded as a `confirm` record — a dialog is
/// its own route, so without that a log cannot tell "confirmed" from "backed
/// out" except by guessing from whether a request followed. The title and
/// message are user-facing text and never go in.
Future<bool> confirmDialog(
  BuildContext context, {
  required String id,
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final t = DashTokens.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => logSurface(
      id,
      AlertDialog(
        // A large system font can make the text taller than the screen; this
        // scrolls it instead of clipping the message.
        scrollable: true,
        icon: icon == null ? null : Icon(icon),
        title: Text(title),
        content: Text(message),
        actions: [
          _ConfirmActions(
            id: id,
            cancelLabel:
                cancelLabel ??
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            cancelStyle: dashNeutralButtonStyle(t),
            confirmLabel: confirmLabel,
            confirmStyle: destructive ? dashDangerButtonStyle(t) : null,
            onAnswer: (answer) => Navigator.pop(dialogContext, answer),
          ),
        ],
      ),
    ),
  );

  final answer = confirmed ?? false;
  DiagnosticRecorder.active?.add(
    LogSource.ui,
    'confirm',
    fields: {'id': id, 'reason': answer ? 'confirmed' : 'cancelled'},
  );
  return answer;
}

class _ConfirmActions extends StatelessWidget {
  const _ConfirmActions({
    required this.id,
    required this.cancelLabel,
    required this.cancelStyle,
    required this.confirmLabel,
    required this.confirmStyle,
    required this.onAnswer,
  });

  final String id;
  final String cancelLabel;
  final ButtonStyle cancelStyle;
  final String confirmLabel;

  /// Null takes the theme's filled button, the brand accent.
  final ButtonStyle? confirmStyle;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) =>
      // The actions sit in an OverflowBar; the widest possible child makes it
      // hand this one the dialog's whole width.
      SizedBox(
        width: double.maxFinite,
        child: _AnswerPair(
          dismiss: FilledButton(
            style: cancelStyle,
            onPressed: () => onAnswer(false),
            child: Text(cancelLabel, textAlign: TextAlign.center),
          ).tagged('$id.cancel'),
          confirm: FilledButton(
            style: confirmStyle,
            onPressed: () => onAnswer(true),
            child: Text(confirmLabel, textAlign: TextAlign.center),
          ).tagged('$id.confirm'),
        ),
      );
}

/// Two children in equal halves of one height, or stacked full-width once
/// either cannot fit its half without breaking a word.
///
/// A render object rather than a `LayoutBuilder`, because a dialog asks its
/// actions for intrinsic sizes, which a `LayoutBuilder` refuses to answer. It
/// also makes the test exact: a button's minimum intrinsic width is its padding
/// plus its longest word.
class _AnswerPair extends MultiChildRenderObjectWidget {
  _AnswerPair({required Widget dismiss, required Widget confirm})
    : super(children: [dismiss, confirm]);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAnswerPair();
}

class _AnswerPairParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderAnswerPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AnswerPairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AnswerPairParentData> {
  static const double _gap = 12;
  static const double _stackGap = 8;

  RenderBox get _dismiss => firstChild!;
  RenderBox get _confirm => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AnswerPairParentData) {
      child.parentData = _AnswerPairParentData();
    }
  }

  double _half(double width) => (width - _gap) / 2;

  bool _sideBySide(double width) =>
      _dismiss.getMinIntrinsicWidth(double.infinity) <= _half(width) &&
      _confirm.getMinIntrinsicWidth(double.infinity) <= _half(width);

  double _heightFor(double width) {
    if (_sideBySide(width)) {
      final half = _half(width);
      return math.max(
        _dismiss.getMaxIntrinsicHeight(half),
        _confirm.getMaxIntrinsicHeight(half),
      );
    }
    return _dismiss.getMaxIntrinsicHeight(width) +
        _stackGap +
        _confirm.getMaxIntrinsicHeight(width);
  }

  double _widthFor(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : getMaxIntrinsicWidth(double.infinity);

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _dismiss.getMinIntrinsicWidth(height),
    _confirm.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _dismiss.getMaxIntrinsicWidth(height) +
      _gap +
      _confirm.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _heightFor(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _heightFor(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = _widthFor(constraints);
    return constraints.constrain(Size(width, _heightFor(width)));
  }

  @override
  void performLayout() {
    final width = _widthFor(constraints);
    final dismissData = _dismiss.parentData! as _AnswerPairParentData;
    final confirmData = _confirm.parentData! as _AnswerPairParentData;

    if (_sideBySide(width)) {
      final half = _half(width);
      final height = _heightFor(width);
      final cell = BoxConstraints.tight(Size(half, height));
      _dismiss.layout(cell);
      _confirm.layout(cell);
      dismissData.offset = Offset.zero;
      confirmData.offset = Offset(half + _gap, 0);
      size = constraints.constrain(Size(width, height));
      return;
    }

    final row = BoxConstraints.tightFor(width: width);
    _dismiss.layout(row, parentUsesSize: true);
    _confirm.layout(row, parentUsesSize: true);
    dismissData.offset = Offset.zero;
    confirmData.offset = Offset(0, _dismiss.size.height + _stackGap);
    size = constraints.constrain(
      Size(width, _dismiss.size.height + _stackGap + _confirm.size.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
