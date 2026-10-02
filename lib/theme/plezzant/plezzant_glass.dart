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

  /// Neutral fill over the backdrop.
  final double fillAlpha;

  /// Palette tint mixed over the fill, from the current ambience.
  final double tintAlpha;

  /// Opaque fallback alpha when blur is unavailable.
  final double solidAlpha;

  /// Soft elevation shadow behind floating glass.
  final double shadowAlpha;

  /// Brightness of the specular edge.
  final double specularAlpha;

  const PlezzantGlassStyle({
    required this.blur,
    required this.fillAlpha,
    required this.tintAlpha,
    required this.solidAlpha,
    this.shadowAlpha = 0.20,
    this.specularAlpha = 0.30,
  });

  /// Navigation rails and top bars. Kept clear so artwork remains present.
  static const chrome = PlezzantGlassStyle(
    blur: 26,
    fillAlpha: 0.055,
    tintAlpha: 0.035,
    solidAlpha: 0.90,
    shadowAlpha: 0.16,
    specularAlpha: 0.28,
  );

  /// Player controls and compact floating panels over video.
  static const overlay = PlezzantGlassStyle(
    blur: 30,
    fillAlpha: 0.075,
    tintAlpha: 0.045,
    solidAlpha: 0.88,
    shadowAlpha: 0.24,
    specularAlpha: 0.34,
  );

  /// Menus, dialogs and sheets that need stronger separation.
  static const panel = PlezzantGlassStyle(
    blur: 34,
    fillAlpha: 0.105,
    tintAlpha: 0.04,
    solidAlpha: 0.95,
    shadowAlpha: 0.28,
    specularAlpha: 0.38,
  );

  /// Very clear glass for small controls floating directly over artwork.
  static const clear = PlezzantGlassStyle(
    blur: 22,
    fillAlpha: 0.035,
    tintAlpha: 0.025,
    solidAlpha: 0.84,
    shadowAlpha: 0.18,
    specularAlpha: 0.42,
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

  static GlassIntensity _intensity() {
    if (DevicePerformance.isReduced) return GlassIntensity.off;
    final settings = SettingsService.instanceOrNull;
    return settings?.read(SettingsService.glassIntensity) ?? GlassIntensity.subtle;
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return _build(context, _intensity());
    return ValueListenableBuilder<GlassIntensity>(
      valueListenable: settings.listenable(SettingsService.glassIntensity),
      builder: (context, _, _) => _build(context, _intensity()),
    );
  }

  Widget _build(BuildContext context, GlassIntensity intensity) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? PlezzantNeutrals.surface : PlezzantNeutrals.lightSurface;
    final lift = dark ? Colors.white : Colors.black;

    return ValueListenableBuilder(
      valueListenable: PlezzantAmbience.instance,
      builder: (context, match, _) {
        final tint = (match?.hue ?? PlezzantPalette.brand).darker;
        final Widget surface;

        switch (intensity) {
          case GlassIntensity.off:
            surface = DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  tint.withValues(alpha: style.tintAlpha * 0.55),
                  base.withValues(alpha: style.solidAlpha),
                ),
                borderRadius: borderRadius,
              ),
              child: _padded(child),
            );

          case GlassIntensity.subtle:
          case GlassIntensity.full:
            final full = intensity == GlassIntensity.full;
            final blur = full ? style.blur : style.blur * 0.72;
            final glassFill = Color.alphaBlend(
              tint.withValues(alpha: style.tintAlpha * (full ? 1.15 : 1.0)),
              Color.alphaBlend(lift.withValues(alpha: style.fillAlpha), base.withValues(alpha: full ? 0.30 : 0.44)),
            );

            final highlight = Color.alphaBlend(Colors.white.withValues(alpha: dark ? 0.08 : 0.16), glassFill);
            final lowerTint = Color.alphaBlend(tint.withValues(alpha: style.tintAlpha * 0.48), glassFill);

            surface = ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.8, -1.0),
                      end: const Alignment(0.8, 1.0),
                      colors: [highlight, glassFill, lowerTint],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                  child: _padded(child),
                ),
              ),
            );
        }

        Widget layered = surface;
        if (intensity != GlassIntensity.off && style.shadowAlpha > 0) {
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
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: const Alignment(-0.7, -1.0),
        end: const Alignment(0.7, 1.0),
        colors: [
          Colors.white.withValues(alpha: alpha),
          Colors.white.withValues(alpha: alpha * 0.45),
          (dark ? Colors.white : Colors.black).withValues(alpha: alpha * 0.12),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularEdgePainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.dark != dark || oldDelegate.alpha != alpha;
}
