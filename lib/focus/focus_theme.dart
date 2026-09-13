import 'package:flutter/material.dart';
import '../services/device_performance.dart';
import '../theme/mono_tokens.dart';
import '../utils/platform_detector.dart';

class FocusTheme {
  FocusTheme._();

  static const double focusScale = 1.055;
  static const double fullCardFocusScale = 1.065;
  static const double focusBorderWidth = 1.5;
  static const double defaultBorderRadius = 18.0;
  static const double focusGlowInnerBlurRadius = 14;
  static const double focusGlowOuterBlurRadius = 28;
  static const double focusGlowSpreadRadius = 0.8;

  static Color getFocusBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72);
  }

  static Duration getAnimationDuration(BuildContext context) {
    if (DevicePerformance.isReduced) return Duration.zero;
    return Theme.of(context).extension<MonoTokens>()?.fast ?? const Duration(milliseconds: 160);
  }

  /// How long a TV row (or the hub list) glides after one D-pad focus step.
  static Duration navigationScrollDuration() =>
      PlatformDetector.isAppleTV() ? const Duration(milliseconds: 500) : const Duration(milliseconds: 150);

  /// [radii] overrides [borderRadius] when per-corner radii are needed.
  static BoxDecoration focusDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
    double borderStrokeAlign = BorderSide.strokeAlignInside,
    Color? color,
  }) {
    final focusColor = color ?? getFocusBorderColor(context);

    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused ? focusColor : Colors.transparent,
        width: focusBorderWidth,
        strokeAlign: borderStrokeAlign,
      ),
    );
  }

  /// The focus glow as a list of [BoxShadow]s.
  static List<BoxShadow> focusGlowShadows(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.20),
        blurRadius: focusGlowInnerBlurRadius,
        spreadRadius: focusGlowSpreadRadius,
      ),
      BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: focusGlowOuterBlurRadius),
    ];
  }

  static double get focusGlowExtent => focusGlowOuterBlurRadius * 2 + focusGlowSpreadRadius;

  static BoxDecoration focusBackgroundDecoration({
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
  }) {
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      color: isFocused ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
    );
  }

  static BoxDecoration textFillFocusDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
  }) {
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      color: isFocused ? tokens(context).text.withValues(alpha: 0.14) : Colors.transparent,
    );
  }
}
