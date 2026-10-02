import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Spacing scale (logical pixels). Layouts compose from these steps instead of
/// literal numbers so rhythm stays consistent across screens.
abstract final class PlezzantSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Horizontal safe inset for TV content (title-safe area on 1080p logical).
  static const double tvInset = 72;
}

/// Corner radii. Media artwork uses [card]; floating glass uses [panel];
/// controls use [control] or [pill].
abstract final class PlezzantRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double control = 14;
  static const double card = 12;
  static const double panel = 24;
  static const double sheet = 28;
  static const double pill = 100;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius panelAll = BorderRadius.all(Radius.circular(panel));
  static const BorderRadius controlAll = BorderRadius.all(Radius.circular(control));
}

/// Motion timings and curves. Reduced-performance devices collapse these to
/// zero through `DevicePerformance.reducedDuration`.
abstract final class PlezzantMotion {
  /// Focus response: fast enough to never trail the D-pad.
  static const Duration focus = Duration(milliseconds: 140);

  /// Colour / ambience cross-fades.
  static const Duration ambience = Duration(milliseconds: 520);

  /// Panels, sheets and chrome reveal.
  static const Duration reveal = Duration(milliseconds: 260);
  static const Duration revealOut = Duration(milliseconds: 180);

  /// Metadata reveal on focused cards.
  static const Duration metadata = Duration(milliseconds: 200);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve exit = Curves.easeInCubic;
}

/// Focus treatment: restrained scale + luminance lift + palette-tinted halo.
abstract final class PlezzantFocus {
  /// Card scale on focus. Small on purpose: no giant zooms, no reflow.
  static const double cardScale = 1.045;
  static const double controlScale = 1.03;

  /// Halo stroke drawn just outside a focused card, palette lighter shade.
  static const double haloWidth = 2.0;
  static const double haloGap = 3.0;
  static const double haloAlpha = 0.85;

  /// Soft palette glow below the halo.
  static const double glowAlpha = 0.28;
  static const double glowBlur = 28;
}
