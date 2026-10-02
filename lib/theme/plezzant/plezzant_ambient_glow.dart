import 'package:flutter/material.dart';

import '../../services/device_performance.dart';
import '../../services/settings_service.dart';
import 'plezzant_ambience.dart';
import 'plezzant_color_matcher.dart';
import 'plezzant_palette.dart';
import 'plezzant_preferences.dart';
import 'plezzant_tokens.dart';

/// Full-bleed contextual light: a large, soft radial wash in the darker shade
/// of the current palette ambience. Sits between artwork and content so heroes
/// and detail pages pick up the colour of what is focused without ever
/// painting an extracted RGB value.
///
/// Neutral context (no match, or ambience switched off) paints nothing.
class PlezzantAmbientGlow extends StatelessWidget {
  /// Where the light source sits; the wash fades out toward the far edge.
  final Alignment center;

  /// Radius as a fraction of the shortest side.
  final double radius;

  /// Multiplier on the intensity-derived alpha, for surfaces that need less.
  final double strength;

  const PlezzantAmbientGlow({
    super.key,
    this.center = const Alignment(-0.85, -0.9),
    this.radius = 1.35,
    this.strength = 1,
  });

  static double alphaFor(AmbienceIntensity intensity) => switch (intensity) {
    AmbienceIntensity.off => 0,
    AmbienceIntensity.subtle => 0.30,
    AmbienceIntensity.rich => 0.50,
  };

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instanceOrNull;
    if (settings == null) return _glow(AmbienceIntensity.subtle);
    return ValueListenableBuilder<AmbienceIntensity>(
      valueListenable: settings.listenable(SettingsService.ambienceIntensity),
      builder: (context, intensity, _) => _glow(intensity),
    );
  }

  Widget _glow(AmbienceIntensity intensity) {
    final alpha = alphaFor(intensity) * strength;
    if (alpha <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: ValueListenableBuilder<PlezzantColorMatch?>(
          valueListenable: PlezzantAmbience.instance,
          builder: (context, match, _) {
            // Transparent target lets the wash fade out instead of snapping to
            // a neutral hue when focus moves to grey artwork.
            final target = match == null ? Colors.transparent : match.shade(PlezzantShade.darker);
            return TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: target),
              duration: DevicePerformance.reducedDuration(PlezzantMotion.ambience),
              curve: PlezzantMotion.standard,
              builder: (context, color, _) {
                final c = color ?? Colors.transparent;
                if (c.a == 0) return const SizedBox.expand();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: center,
                      radius: radius,
                      colors: [
                        c.withValues(alpha: c.a * alpha),
                        c.withValues(alpha: c.a * alpha * 0.35),
                        c.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: const SizedBox.expand(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
