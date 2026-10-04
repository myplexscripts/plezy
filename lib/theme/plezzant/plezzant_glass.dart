import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../services/device_performance.dart';
import '../../services/settings_service.dart';
import 'plezzant_ambience.dart';
import 'plezzant_palette.dart';
import 'plezzant_preferences.dart';
import 'plezzant_tokens.dart';

/// Material recipe for one glass surface.
@immutable
class PlezzantGlassStyle {
  /// Backdrop blur sigma. Zero skips the BackdropFilter entirely.
  final double blur;

  /// White lift over the backdrop: what makes glass read as glass.
  final double fillAlpha;

  /// Palette tint mixed over the fill, from the current ambience.
  final double tintAlpha;

  /// Dark base under the lift while the backdrop is blurred.
  final double baseAlpha;

  /// Dark base when blur is unavailable: more opaque, so nothing sharp
  /// behind it competes with the content.
  final double solidAlpha;

  /// Soft elevation shadow behind floating glass.
  final double shadowAlpha;

  /// Brightness of the specular edge.
  final double specularAlpha;

  const PlezzantGlassStyle({
    required this.blur,
    required this.fillAlpha,
    required this.tintAlpha,
    required this.baseAlpha,
    required this.solidAlpha,
    this.shadowAlpha = 0.20,
    this.specularAlpha = 0.30,
  });

  /// Navigation chips and top bars. Clear, bright glass over artwork.
  static const chrome = PlezzantGlassStyle(
    blur: 24,
    fillAlpha: 0.14,
    tintAlpha: 0.04,
    baseAlpha: 0.16,
    solidAlpha: 0.62,
    shadowAlpha: 0.18,
    specularAlpha: 0.55,
  );

  /// Player controls and compact floating panels over video.
  static const overlay = PlezzantGlassStyle(
    blur: 30,
    fillAlpha: 0.11,
    tintAlpha: 0.0,
    baseAlpha: 0.30,
    solidAlpha: 0.84,
    shadowAlpha: 0.24,
    specularAlpha: 0.45,
  );

  /// Menus, dialogs, sheets and the open sidebar: content must win.
  static const panel = PlezzantGlassStyle(
    blur: 40,
    fillAlpha: 0.08,
    tintAlpha: 0.04,
    baseAlpha: 0.56,
    solidAlpha: 0.95,
    shadowAlpha: 0.30,
    specularAlpha: 0.40,
  );

  /// Very clear glass for small controls floating directly over artwork.
  static const clear = PlezzantGlassStyle(
    blur: 20,
    fillAlpha: 0.12,
    tintAlpha: 0.03,
    baseAlpha: 0.10,
    solidAlpha: 0.56,
    shadowAlpha: 0.18,
    specularAlpha: 0.58,
  );
}

/// A Liquid-Glass-inspired functional layer for navigation, controls, menus
/// and overlays. Content itself stays solid so hierarchy remains obvious.
///
/// The material combines backdrop blur, a faint ambience tint, a directional
/// highlight and a thin specular edge. Reduced-performance devices and the
/// user's glass setting fall back to a solid surface with the same geometry.
class PlezzantGlass extends StatelessWidget {
  final Widget child;
  final PlezzantGlassStyle style;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Draw the hairline specular edge. Disable for full-bleed bars.
  final bool edge;

  const PlezzantGlass({
    super.key,
    required this.child,
    this.style = PlezzantGlassStyle.panel,
    this.borderRadius = PlezzantRadius.panelAll,
    this.padding,
    this.edge = true,
  });

  static GlassIntensity _intensity(BuildContext context) {
    if (DevicePerformance.isReduced) return GlassIntensity.off;
    // High contrast: opaque surfaces, the closest Android equivalent of
    // Apple's Reduce Transparency.
    if (MediaQuery.highContrastOf(context)) return GlassIntensity.off;
    final settings = SettingsService.instanceOrNull;
    return settings?.read(SettingsService.glassIntensity) ?? GlassIntensity.subtle;
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return _build(context, _intensity(context));
    return ValueListenableBuilder<GlassIntensity>(
      valueListenable: settings.listenable(SettingsService.glassIntensity),
      builder: (context, _, _) => _build(context, _intensity(context)),
    );
  }

  /// Lifts the blurred backdrop's saturation and brightness a touch, the
  /// "vibrancy" that separates real glass from a dark translucent slab.
  static const ColorFilter _vibrancy = ColorFilter.matrix(<double>[
    1.28, -0.24, -0.04, 0, 6, //
    -0.08, 1.12, -0.04, 0, 6, //
    -0.08, -0.24, 1.32, 0, 6, //
    0, 0, 0, 1, 0, //
  ]);

  Widget _build(BuildContext context, GlassIntensity intensity) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? PlezzantNeutrals.surface : PlezzantNeutrals.lightSurface;
    final lift = dark ? Colors.white : Colors.black;

    return ValueListenableBuilder(
      valueListenable: PlezzantAmbience.instance,
      builder: (context, match, _) {
        final tint = (match?.hue ?? PlezzantPalette.brand).darker;
        final full = intensity == GlassIntensity.full;
        final blur = intensity == GlassIntensity.off
            ? 0.0
            : math.min(full ? style.blur : style.blur * 0.8, DevicePerformance.maxGlassBlur);
        final blurred = blur > 0;

        // Without blur the base carries the separation; the white lift, sheen
        // and specular edge keep the same glass character either way.
        final fill = Color.alphaBlend(
          tint.withValues(alpha: style.tintAlpha),
          Color.alphaBlend(
            lift.withValues(alpha: style.fillAlpha),
            base.withValues(alpha: blurred ? style.baseAlpha : style.solidAlpha),
          ),
        );
        Widget surface = DecoratedBox(
          decoration: BoxDecoration(color: fill),
          child: DecoratedBox(
            // Top sheen: light falling on the upper half of the pane.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.10 : 0.18),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: dark ? 0.06 : 0.0),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: _padded(child),
          ),
        );
        if (blurred) {
          surface = BackdropFilter(
            filter: ImageFilter.compose(
              outer: _vibrancy,
              inner: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.mirror),
            ),
            child: surface,
          );
        }
        surface = ClipRRect(borderRadius: borderRadius, child: surface);

        Widget layered = surface;
        if (style.shadowAlpha > 0) {
          layered = DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? style.shadowAlpha : style.shadowAlpha * 0.42),
                  blurRadius: 30,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: surface,
          );
        }

        if (!edge) return layered;
        return CustomPaint(
          foregroundPainter: _SpecularEdgePainter(borderRadius: borderRadius, dark: dark, alpha: style.specularAlpha),
          child: layered,
        );
      },
    );
  }

  Widget _padded(Widget child) => padding == null ? child : Padding(padding: padding!, child: child);
}

/// Thin directional catch-light around the glass perimeter.
class _SpecularEdgePainter extends CustomPainter {
  final BorderRadius borderRadius;
  final bool dark;
  final double alpha;

  const _SpecularEdgePainter({required this.borderRadius, required this.dark, required this.alpha});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: alpha),
          Colors.white.withValues(alpha: alpha * 0.30),
          Colors.white.withValues(alpha: alpha * 0.16),
          (dark ? Colors.white : Colors.black).withValues(alpha: alpha * 0.38),
        ],
        stops: const [0.0, 0.38, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularEdgePainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.dark != dark || oldDelegate.alpha != alpha;
}
