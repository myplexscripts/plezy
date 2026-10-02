import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Get the replay icon based on the duration
/// Returns numbered icons (replay_5, replay_10, replay_30) when available,
/// otherwise returns generic replay icon
IconData getReplayIcon(int seconds) {
  switch (seconds) {
    case 5:
      return LucideIcons.rotateCcw;
    case 10:
      return LucideIcons.rotateCcw;
    case 30:
      return LucideIcons.rotateCcw;
    default:
      return LucideIcons.rotateCcw;
  }
}

/// Get the forward icon based on the duration
/// Returns numbered icons (forward_5, forward_10, forward_30) when available,
/// otherwise returns generic forward icon
IconData getForwardIcon(int seconds) {
  switch (seconds) {
    case 5:
      return LucideIcons.rotateCw;
    case 10:
      return LucideIcons.rotateCw;
    case 30:
      return LucideIcons.rotateCw;
    default:
      return LucideIcons.skipForward;
  }
}
