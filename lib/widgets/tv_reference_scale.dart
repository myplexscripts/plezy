import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/plezzant/plezzant_tokens.dart';
import '../utils/platform_detector.dart';

/// Lays [child] out on Plezzant's 1920x1080 TV reference canvas and paints it
/// scaled to the device, so TV chrome can be authored directly in
/// [PlezzantTv] / `PlezzantTvType` units.
///
/// Inside the subtree [MediaQuery] reports the reference-canvas size, so
/// [PlezzantTv.scaleOf] returns 1.0 there while it returns the device factor
/// outside. Helpers that multiply a reference value by [PlezzantTv.scaleOf]
/// therefore give the right answer in either coordinate space.
///
/// A pass-through off TV or when the device already matches the reference.
class TvReferenceScale extends StatelessWidget {
  final Widget child;

  const TvReferenceScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isTV()) return child;
    final media = MediaQuery.of(context);
    final scale = PlezzantTv.scaleForHeight(media.size.height);
    if ((scale - 1).abs() < 0.001) return child;
    return _ReferenceScaleBox(
      scale: scale,
      child: MediaQuery(
        data: media.copyWith(
          size: media.size / scale,
          devicePixelRatio: media.devicePixelRatio * scale,
          padding: media.padding / scale,
          viewPadding: media.viewPadding / scale,
          viewInsets: media.viewInsets / scale,
        ),
        child: child,
      ),
    );
  }
}

class _ReferenceScaleBox extends SingleChildRenderObjectWidget {
  final double scale;

  const _ReferenceScaleBox({required this.scale, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderReferenceScaleBox(scale);

  @override
  void updateRenderObject(BuildContext context, _RenderReferenceScaleBox renderObject) {
    renderObject.scale = scale;
  }
}

/// Lays the child out with constraints divided by [scale], sizes itself to the
/// child's size multiplied by [scale], and maps paint, hit testing and
/// [applyPaintTransform] (focus scrolling, overlays) through the same factor.
class _RenderReferenceScaleBox extends RenderProxyBox {
  _RenderReferenceScaleBox(this._scale);

  double _scale;
  double get scale => _scale;
  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
    markNeedsLayout();
  }

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1);

  BoxConstraints _childConstraints(BoxConstraints constraints) => BoxConstraints(
    minWidth: constraints.minWidth / _scale,
    maxWidth: constraints.maxWidth / _scale,
    minHeight: constraints.minHeight / _scale,
    maxHeight: constraints.maxHeight / _scale,
  );

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(child.size * _scale);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(child.getDryLayout(_childConstraints(constraints)) * _scale);
  }

  @override
  double computeMinIntrinsicWidth(double height) => (child?.getMinIntrinsicWidth(height / _scale) ?? 0) * _scale;

  @override
  double computeMaxIntrinsicWidth(double height) => (child?.getMaxIntrinsicWidth(height / _scale) ?? 0) * _scale;

  @override
  double computeMinIntrinsicHeight(double width) => (child?.getMinIntrinsicHeight(width / _scale) ?? 0) * _scale;

  @override
  double computeMaxIntrinsicHeight(double width) => (child?.getMaxIntrinsicHeight(width / _scale) ?? 0) * _scale;

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}

/// Lays list-style TV screens (settings, forms, menus) out on a slightly
/// larger logical canvas so their phone-unit rows, controls and type land at
/// the same physical size as the reference-canvas chrome on Home and the
/// detail pages. Values authored in [PlezzantTv] units through
/// [PlezzantTv.scaleOf] keep their size, because the reported [MediaQuery]
/// size grows by the same factor.
///
/// A pass-through off TV.
class TvComfortScale extends StatelessWidget {
  final Widget child;

  const TvComfortScale({super.key, required this.child});

  /// Phone-unit content renders at this fraction of its 540-canvas size: a
  /// 17pt list title lands near the 26px reference body role.
  static const double factor = 0.76;

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isTV()) return child;
    final media = MediaQuery.of(context);
    return _ReferenceScaleBox(
      scale: factor,
      child: MediaQuery(
        data: media.copyWith(
          size: media.size / factor,
          devicePixelRatio: media.devicePixelRatio * factor,
          padding: media.padding / factor,
          viewPadding: media.viewPadding / factor,
          viewInsets: media.viewInsets / factor,
        ),
        child: child,
      ),
    );
  }
}
