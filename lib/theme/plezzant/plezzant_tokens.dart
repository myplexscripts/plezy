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
  /// Focus should feel immediate, but still have enough travel to read as a
  /// physical change in depth.
  static const Duration focus = Duration(milliseconds: 180);

  /// Colour and ambience cross-fades are deliberately slower than controls.
  static const Duration ambience = Duration(milliseconds: 620);

  /// Panels, sheets and floating chrome.
  static const Duration reveal = Duration(milliseconds: 340);
  static const Duration revealOut = Duration(milliseconds: 220);

  /// Metadata reveal on focused cards.
  static const Duration metadata = Duration(milliseconds: 240);

  /// Root navigation and pushed-page transitions.
  static const Duration navigation = Duration(milliseconds: 320);
  static const Duration route = Duration(milliseconds: 420);
  static const Duration routeOut = Duration(milliseconds: 260);

  /// Hero artwork and metadata changes should drift rather than snap.
  static const Duration hero = Duration(milliseconds: 440);

  /// A soft deceleration similar to the way tvOS lets objects settle.
  static const Curve standard = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);
}

/// Focus treatment: restrained scale + luminance lift + palette-tinted halo.
abstract final class PlezzantFocus {
  /// tvOS communicates focus primarily through depth. The scale remains small
  /// enough to avoid reflow while reading more clearly from couch distance.
  static const double cardScale = 1.055;
  static const double fullCardScale = 1.065;
  static const double controlScale = 1.035;
  static const double lift = 3.5;

  /// A thin catch-light and a wide, low-opacity bloom read more like reflected
  /// light than a conventional selection outline.
  static const double haloWidth = 1.25;
  static const double haloGap = 2.0;
  static const double haloAlpha = 0.78;

  static const double glowAlpha = 0.22;
  static const double glowBlur = 38;
}
