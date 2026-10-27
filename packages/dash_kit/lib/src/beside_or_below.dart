import 'package:dash_ui/dash_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// A label and its control: side by side while both fit, the control under the
/// label otherwise, and then spanning the full width.
///
/// A `Wrap` gets the stacked case wrong: the control that moved to the next line
/// keeps its content width and sticks to the left edge instead of using the room.
/// Here the [control] gets exactly its intrinsic width beside the label and the
/// whole width under it, so it must be a widget that fills the width it is given
/// (a `SegmentedButton`, a `Row` of `Expanded` buttons) and supports intrinsic
/// widths (no `LayoutBuilder`). Fits means the label and the control at their
/// intrinsic widths plus the [gap].
class BesideOrBelow extends MultiChildRenderObjectWidget {
  BesideOrBelow({
    super.key,
    required Widget label,
    required Widget control,
    this.gap = DashSpace.md,
    this.runGap = DashSpace.sm,
  }) : super(children: [label, control]);

  final double gap;
  final double runGap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBesideOrBelow(gap: gap, runGap: runGap);

  @override
  void updateRenderObject(BuildContext context, _RenderBesideOrBelow render) {
    render
      ..gap = gap
      ..runGap = runGap;
  }
}

class _RenderBesideOrBelow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderBesideOrBelow({required double gap, required double runGap})
    : _gap = gap,
      _runGap = runGap;

  double _gap;
  double get gap => _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _runGap;
  double get runGap => _runGap;
  set runGap(double v) {
    if (v == _runGap) return;
    _runGap = v;
    markNeedsLayout();
  }

  RenderBox get _label => firstChild!;
  RenderBox get _control => lastChild!;

  double get _labelWidth => _label.getMaxIntrinsicWidth(double.infinity);
  double get _controlWidth => _control.getMaxIntrinsicWidth(double.infinity);

  bool _stackedIn(double maxWidth) =>
      maxWidth.isFinite && _labelWidth + _gap + _controlWidth > maxWidth;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => _label
      .getMinIntrinsicWidth(height)
      .clamp(_control.getMinIntrinsicWidth(height), double.infinity);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _labelWidth + _gap + _controlWidth;

  double _heightFor(double width) {
    if (_stackedIn(width)) {
      return _label.getMinIntrinsicHeight(width) +
          _runGap +
          _control.getMinIntrinsicHeight(width);
    }
    final labelH = _label.getMinIntrinsicHeight(_labelWidth);
    final controlH = _control.getMinIntrinsicHeight(_controlWidth);
    return labelH > controlH ? labelH : controlH;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _heightFor(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _heightFor(width);

  double _widthFor(BoxConstraints constraints) => constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : computeMaxIntrinsicWidth(double.infinity);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = _widthFor(constraints);
    final labelH = _label.getDryLayout(BoxConstraints(maxWidth: width)).height;
    if (_stackedIn(constraints.maxWidth)) {
      final controlH = _control
          .getDryLayout(BoxConstraints.tightFor(width: width))
          .height;
      return constraints.constrain(Size(width, labelH + _runGap + controlH));
    }
    final controlH = _control
        .getDryLayout(BoxConstraints.tightFor(width: _controlWidth))
        .height;
    return constraints.constrain(
      Size(width, labelH > controlH ? labelH : controlH),
    );
  }

  @override
  void performLayout() {
    final width = _widthFor(constraints);
    final stacked = _stackedIn(constraints.maxWidth);
    final labelData = _label.parentData! as MultiChildLayoutParentData;
    final controlData = _control.parentData! as MultiChildLayoutParentData;

    _label.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
    if (stacked) {
      _control.layout(
        BoxConstraints.tightFor(width: width),
        parentUsesSize: true,
      );
      labelData.offset = Offset.zero;
      controlData.offset = Offset(0, _label.size.height + _runGap);
      size = constraints.constrain(
        Size(width, _label.size.height + _runGap + _control.size.height),
      );
    } else {
      _control.layout(
        BoxConstraints.tightFor(width: _controlWidth),
        parentUsesSize: true,
      );
      final height = _label.size.height > _control.size.height
          ? _label.size.height
          : _control.size.height;
      labelData.offset = Offset(0, (height - _label.size.height) / 2);
      controlData.offset = Offset(
        width - _control.size.width,
        (height - _control.size.height) / 2,
      );
      size = constraints.constrain(Size(width, height));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
