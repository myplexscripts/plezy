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

  /// Neutral fill over the backdrop (white-on-dark lift).
  final double fillAlpha;

  /// Palette tint mixed over the fill, from the current ambience.
  final double tintAlpha;

  /// Opaque fallback alpha when blur is unavailable (weak hardware / off).
  final double solidAlpha;

  const PlezzantGlassStyle({
    required this.blur,
    required this.fillAlpha,
    required this.tintAlpha,
    required this.solidAlpha,
  });

  /// Navigation rails and top bars: light, mostly transparent.
  static const chrome = PlezzantGlassStyle(blur: 24, fillAlpha: 0.06, tintAlpha: 0.05, solidAlpha: 0.92);

  /// Player controls and floating panels over video.
  static const overlay = PlezzantGlassStyle(blur: 28, fillAlpha: 0.10, tintAlpha: 0.06, solidAlpha: 0.88);

  /// Menus, dialogs and sheets that must stay highly readable.
  static const panel = PlezzantGlassStyle(blur: 32, fillAlpha: 0.12, tintAlpha: 0.05, solidAlpha: 0.96);
}

/// A restrained Liquid-Glass-inspired surface: blurred backdrop, neutral lift,
/// faint palette tint from the current ambience, and a specular top edge.
///
/// Glass is for floating UI only (navigation, player chrome, menus, dialogs,
/// context panels). Content stays solid. When the device runs the reduced
/// performance tier or the user turned glass off, the surface renders as a
/// solid near-black panel with the same shape and edge, so layouts and
/// contrast never depend on blur.
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
                  tint.withValues(alpha: style.tintAlpha * 0.6),
                  base.withValues(alpha: style.solidAlpha),
                ),
                borderRadius: borderRadius,
              ),
              child: _padded(child),
            );
          case GlassIntensity.subtle:
          case GlassIntensity.full:
            final full = intensity == GlassIntensity.full;
            final blur = full ? style.blur : style.blur * 0.66;
            final fill = Color.alphaBlend(
              tint.withValues(alpha: style.tintAlpha * (full ? 1.2 : 1.0)),
              Color.alphaBlend(lift.withValues(alpha: style.fillAlpha), base.withValues(alpha: full ? 0.38 : 0.55)),
            );
            surface = ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: fill),
                  child: _padded(child),
                ),
              ),
            );
        }
        if (!edge) return surface;
        return CustomPaint(
          foregroundPainter: _SpecularEdgePainter(borderRadius: borderRadius, dark: dark),
          child: surface,
        );
      },
    );
  }

  Widget _padded(Widget child) => padding == null ? child : Padding(padding: padding!, child: child);
}

/// One-pixel edge, brighter along the top: the "specular" catch-light that
/// makes a glass panel read as a physical layer without a heavy border.
class _SpecularEdgePainter extends CustomPainter {
  final BorderRadius borderRadius;
  final bool dark;

  const _SpecularEdgePainter({required this.borderRadius, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(0.5);
    final light = dark ? Colors.white : Colors.black;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          light.withValues(alpha: dark ? 0.22 : 0.10),
          light.withValues(alpha: dark ? 0.05 : 0.04),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularEdgePainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.dark != dark;
}
