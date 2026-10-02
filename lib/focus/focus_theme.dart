import 'package:flutter/material.dart';
import '../services/device_performance.dart';
import '../theme/mono_tokens.dart';
import '../theme/plezzant/plezzant_ambience.dart';
import '../theme/plezzant/plezzant_palette.dart';
import '../theme/plezzant/plezzant_tokens.dart';
import '../utils/platform_detector.dart';

class FocusTheme {
  FocusTheme._();

  static const double focusScale = PlezzantFocus.cardScale;
  static const double fullCardFocusScale = PlezzantFocus.fullCardScale;
  static const double focusLift = PlezzantFocus.lift;
  static const double focusBorderWidth = PlezzantFocus.haloWidth;
  static const double defaultBorderRadius = 8.0;
  static const double focusGlowInnerBlurRadius = 22;
  static const double focusGlowOuterBlurRadius = PlezzantFocus.glowBlur;
  static const double focusGlowSpreadRadius = 1.0;

  /// Crisp neutral edge. Kept thin and slightly translucent so focus reads
  /// as light on the card rather than as an outline.
  static Color getFocusBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    final neutral = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    final accent = PlezzantAmbience.instance.accent(PlezzantShade.lighter);
    return Color.lerp(neutral, accent, 0.24)!.withValues(alpha: theme.brightness == Brightness.dark ? 0.82 : 0.64);
  }

  /// Soft halo under the focused item, tinted by the current palette ambience
  /// (artwork-matched hue, lighter shade). Neutral context uses the brand hue.
  static Color getFocusGlowColor(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) return Theme.of(context).colorScheme.primary;
    return PlezzantAmbience.instance.accent(PlezzantShade.lighter);
  }

  static Duration getAnimationDuration(BuildContext context) {
    // Reduced tier: snap focus transitions (scale/border/glow) instead of
    // animating — each animation frame re-rasterizes the focused card.
    if (DevicePerformance.isReduced) return Duration.zero;
    return Theme.of(context).extension<MonoTokens>()?.fast ?? const Duration(milliseconds: 150);
  }

  /// How long a TV row (or the hub list) glides after one D-pad focus step.
  ///
  /// Apple TV keeps the ~500ms ease-out measured from the native focus
  /// engine's scrollable containers (issue #2006): Siri Remote swipes chain
  /// steps into one continuous glide and users expect that inertia. D-pad
  /// platforms have no such reference: Leanback's `GridLayoutManager` prices a
  /// one-card step at roughly 100-150ms, so a 500ms glide there trails the
  /// focus border on every press and reads as input lag next to the launcher.
  /// Successive presses (including hold-repeats) retarget the animation from
  /// wherever the row currently is, so a fast series still glides continuously.
  static Duration navigationScrollDuration() =>
      PlatformDetector.isAppleTV() ? const Duration(milliseconds: 500) : const Duration(milliseconds: 150);

  /// [radii] overrides [borderRadius] when per-corner radii are needed
  /// (M3E grouped cards: large outer / small inner corners).
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
  ///
  /// Rendered by [FocusGlowOverlay] in the root overlay so the glow paints
  /// above sibling cards on all four sides (an in-tree background shadow is
  /// occluded by later-painted neighbours, which produced the one-sided halo).
  static List<BoxShadow> focusGlowShadows(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.34),
        blurRadius: focusGlowInnerBlurRadius,
        spreadRadius: focusGlowSpreadRadius,
      ),
      BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: focusGlowOuterBlurRadius, spreadRadius: 1),
    ];
  }

  /// How far the focus glow visibly reaches beyond the card edge. Used to size
  /// the overlay paint area so the blur is not clipped.
  static double get focusGlowExtent => focusGlowOuterBlurRadius * 2 + focusGlowSpreadRadius;

  /// Build focus decoration with background color instead of border.
  /// Useful for video controls where it should match the native hover style.
  /// [radii] overrides [borderRadius] when per-corner radii are needed.
  static BoxDecoration focusBackgroundDecoration({
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
  }) {
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      color: isFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
    );
  }

  /// Focus background fill derived from the theme's text color, so it stays
  /// visible on BOTH light and dark surfaces — the white-based
  /// [focusBackgroundDecoration] disappears on light ones. This is the mono
  /// convention used by [TrackRow], the navigation rail, and the music player
  /// surfaces. Prefer this for any new mono-themed surface.
  static BoxDecoration textFillFocusDecoration(
    BuildContext context, {
    required bool isFocused,
    double borderRadius = defaultBorderRadius,
    BorderRadius? radii,
  }) {
    return BoxDecoration(
      borderRadius: radii ?? BorderRadius.circular(borderRadius),
      color: isFocused ? tokens(context).text.withValues(alpha: 0.12) : Colors.transparent,
    );
  }
}
