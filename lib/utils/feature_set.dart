import 'package:flutter/foundation.dart';

import 'platform_detector.dart';

/// Which settings and player options a surface offers.
///
/// On a TV Plezzant shows the everyday set a viewer reaches for (quality,
/// subtitles, audio, auto-play and skipping, theme, card style, spoilers) and
/// leaves power-user tuning (decoders, shaders, mpv config, buffers, debug
/// overlays, per-device layout knobs) at its defaults, like Plex's own TV
/// app. Phones, tablets and desktops keep every option.
abstract final class FeatureSet {
  /// Power-user settings and player tools are offered.
  static bool get advanced => debugAdvancedOverride ?? !PlatformDetector.isTV();

  /// Tests that exercise power-user flows on a TV form factor pin this.
  @visibleForTesting
  static bool? debugAdvancedOverride;
}
