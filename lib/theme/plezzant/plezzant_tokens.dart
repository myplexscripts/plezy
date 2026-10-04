import 'package:flutter/widgets.dart';

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

  /// Legacy alias retained while TV call sites migrate to [PlezzantTv.safeX].
  static const double tvInset = PlezzantTv.safeX;
}

/// Large-screen composition tokens for Plezzant's 1920x1080 reference canvas.
///
/// Artwork and ambience may bleed to the display edge. Critical foreground
/// content follows the safe frame, and TV widgets scale these values instead
/// of inventing local gutters.
abstract final class PlezzantTv {
  /// Height of the reference canvas every TV token is expressed in.
  static const double referenceHeight = 1080;

  /// Reference units → logical pixels. A Google TV lays a 1080p panel out at
  /// 960x540 logical pixels, so the factor there is 0.5 and an 80 unit inset
  /// lands on 80 physical pixels, exactly where tvOS puts it. There is
  /// deliberately no comfort floor: clamping it up is what made the TV UI
  /// render oversized and cramped on real hardware.
  static double scaleForHeight(double height) => (height / referenceHeight).clamp(0.4, 2.0).toDouble();

  static double scaleOf(BuildContext context) => scaleForHeight(MediaQuery.sizeOf(context).height);

  static const double safeX = 80;
  static const double safeY = 60;

  static const double sidebarInset = 32;
  static const double sidebarWidth = 336;

  /// Left edge of the TV content column. Screens add their own inset on top
  /// (the browse rail adds [safeX] minus this), landing shelf titles on [safeX].
  static const double sidebarCollapsedWidth = 56;

  /// The "‹ Home" section pill floating over non-home content.
  static const double sectionPillTop = 44;
  static const double sectionPillLeft = 56;

  /// Content on non-home tabs starts below the pill.
  static const double sectionPillBand = 116;
  static const double sidebarHorizontalPadding = 20;
  static const double navRowHeight = 58;
  static const double navPanelRadius = 30;

  static const double homeCardGap = 24;
  static const double focusOverflow = 18;
  static const double shelfTitleHeight = 64;
  static const double heroTextWidth = 720;
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
  static const Duration focus = Duration(milliseconds: 170);
  static const Duration focusOut = Duration(milliseconds: 200);
  static const Duration press = Duration(milliseconds: 100);

  static const Duration ambience = Duration(milliseconds: 620);

  static const Duration reveal = Duration(milliseconds: 340);
  static const Duration revealOut = Duration(milliseconds: 240);

  static const Duration metadata = Duration(milliseconds: 260);

  static const Duration navigation = Duration(milliseconds: 340);
  static const Duration route = Duration(milliseconds: 420);
  static const Duration routeOut = Duration(milliseconds: 280);

  static const Duration hero = Duration(milliseconds: 440);
  static const Duration heroCopy = Duration(milliseconds: 260);

  static const Curve standard = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);
}

/// Focus treatment: restrained scale, physical lift and soft illumination.
abstract final class PlezzantFocus {
  static const double cardScale = 1.05;
  static const double fullCardScale = 1.055;
  static const double controlScale = 1.03;
  static const double lift = 6;

  static const double haloWidth = 1.2;
  static const double haloGap = 2.0;
  static const double haloAlpha = 0.72;

  static const double glowAlpha = 0.20;
  static const double glowBlur = 32;
}
