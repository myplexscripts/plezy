import 'package:flutter/material.dart';

/// The single wrapper every application icon goes through.
///
/// Plezzant draws Lucide icons (`package:lucide_icons_flutter`) at Lucide's
/// canonical 2px stroke. Lucide glyphs are outline-only, so the historical
/// [fill] parameter now expresses *state* instead of shape: a [fill] below 0.5
/// renders the icon at reduced emphasis, which keeps "on/off" affordances
/// (watch-together active, favourite set) distinguishable without a second
/// icon family. [weight], [grade] and [opticalSize] are accepted for API
/// compatibility and ignored, because Lucide has no variable axes.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
  });

  final IconData? icon;
  final double? size;
  final Color? color;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;

  /// Emphasis applied to an icon whose [fill] marks it as "off".
  static const double inactiveEmphasis = 0.55;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const SizedBox.shrink();
    var effectiveColor = color ?? AppIconDefaults.color;
    final effectiveFill = fill ?? AppIconDefaults.fill;
    if (effectiveFill < 0.5) {
      final base = effectiveColor ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color;
      if (base != null) effectiveColor = base.withValues(alpha: base.a * inactiveEmphasis);
    }
    return Icon(
      icon,
      size: size,
      color: effectiveColor,
      shadows: shadows ?? AppIconDefaults.shadows,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}

/// Central place to adjust default icon presentation.
class AppIconDefaults {
  static double fill = 1;
  static double weight = 400;
  static double? grade;
  static double? opticalSize;
  static Color? color;
  static List<Shadow>? shadows;

  static void update({
    double? fill,
    double? weight,
    double? grade,
    double? opticalSize,
    Color? color,
    List<Shadow>? shadows,
  }) {
    if (fill != null) AppIconDefaults.fill = fill;
    if (weight != null) AppIconDefaults.weight = weight;
    if (grade != null) AppIconDefaults.grade = grade;
    if (opticalSize != null) AppIconDefaults.opticalSize = opticalSize;
    if (color != null) AppIconDefaults.color = color;
    if (shadows != null) AppIconDefaults.shadows = shadows;
  }
}
