import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'plezzant_palette.dart';
import 'ultra_blur.dart';

/// Flat, colour-tinted TV controls.
///
/// Controls live in the lower-left of the screen, over the blur's
/// bottom-left colour, so they take that colour's complement: a title with a
/// deep blue corner gets amber controls, a green one gets rose. The tint is
/// a plain translucent fill with a soft edge, so it reads the same whether or
/// not the device can blur (no frosted slab turning into opaque grey).
@immutable
class ControlTints {
  const ControlTints({
    required this.idleFill,
    required this.idleEdge,
    required this.focusFill,
    required this.focusForeground,
    required this.accent,
  });

  /// Resting fill: the complement at moderate strength over the blur.
  final Color idleFill;

  /// Soft rim around a resting control.
  final Color idleEdge;

  /// Focused fill: a near-white wash of the same hue (maximum contrast).
  final Color focusFill;

  /// Label and icon colour on [focusFill].
  final Color focusForeground;

  /// The pure complement, for small accents.
  final Color accent;

  /// Labels and icons on a resting control.
  Color get idleForeground => Colors.white;

  /// Neutral default before any artwork has resolved: the brand hue.
  static final ControlTints fallback = ControlTints.fromAccent(PlezzantPalette.brand.shade(PlezzantShade.original));

  /// The complement of [blur]'s bottom-left corner (the colour sitting
  /// behind the controls).
  factory ControlTints.fromBlur(UltraBlurColors? blur) {
    if (blur == null) return fallback;
    final base = HSLColor.fromColor(blur.bottomLeft);
    // Near-grey corners have no hue worth complementing: keep the brand hue.
    if (base.saturation < 0.10) return fallback;
    final hue = (base.hue + 180) % 360;
    return ControlTints.fromAccent(HSLColor.fromAHSL(1, hue, 0.74, 0.54).toColor());
  }

  factory ControlTints.fromAccent(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return ControlTints(
      idleFill: hsl
          .withSaturation(math.min(hsl.saturation, 0.62))
          .withLightness(0.46)
          .toColor()
          .withValues(alpha: 0.56),
      idleEdge: hsl.withLightness(0.74).toColor().withValues(alpha: 0.40),
      focusFill: hsl.withSaturation(0.55).withLightness(0.93).toColor(),
      focusForeground: hsl.withSaturation(0.55).withLightness(0.14).toColor(),
      accent: accent,
    );
  }

  static ControlTints lerp(ControlTints a, ControlTints b, double t) => ControlTints(
    idleFill: Color.lerp(a.idleFill, b.idleFill, t)!,
    idleEdge: Color.lerp(a.idleEdge, b.idleEdge, t)!,
    focusFill: Color.lerp(a.focusFill, b.focusFill, t)!,
    focusForeground: Color.lerp(a.focusForeground, b.focusForeground, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
  );

  /// The tints for whatever title the blur currently follows.
  static ControlTints get current => ControlTints.fromBlur(UltraBlurAmbience.instance.value);
}

class _TintsTween extends Tween<ControlTints> {
  _TintsTween({super.end});

  @override
  ControlTints lerp(double t) => ControlTints.lerp(begin ?? end!, end!, t);
}

/// Rebuilds [builder] with the current [ControlTints], gliding between titles.
class ControlTintBuilder extends StatelessWidget {
  const ControlTintBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ControlTints tints) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UltraBlurColors?>(
      valueListenable: UltraBlurAmbience.instance,
      builder: (context, blur, _) => TweenAnimationBuilder<ControlTints>(
        tween: _TintsTween(end: ControlTints.fromBlur(blur)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, tints, _) => builder(context, tints),
      ),
    );
  }
}

/// A flat tinted pill or disc: the TV control surface. The [child] draws its
/// labels in white.
class TintedControl extends StatelessWidget {
  const TintedControl({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ControlTintBuilder(
      builder: (context, tints) => DecoratedBox(
        decoration: BoxDecoration(
          color: tints.idleFill,
          borderRadius: borderRadius,
          border: Border.all(color: tints.idleEdge, width: 1.2),
        ),
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}
