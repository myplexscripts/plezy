import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../i18n/strings.g.dart';
import '../../services/music/music_playback_service.dart';

/// Shared repeat-mode presentation for the now-playing transport row and the
/// queue sheet header: icon, accessibility label, and the off→all→one cycle.
IconData repeatModeIcon(MusicRepeatMode mode) => switch (mode) {
  MusicRepeatMode.off => LucideIcons.repeat,
  MusicRepeatMode.all => LucideIcons.repeat,
  MusicRepeatMode.one => LucideIcons.repeat1,
};

String repeatModeLabel(MusicRepeatMode mode) => switch (mode) {
  MusicRepeatMode.off => t.music.repeat,
  MusicRepeatMode.all => t.music.repeatAll,
  MusicRepeatMode.one => t.music.repeatOne,
};

MusicRepeatMode nextRepeatMode(MusicRepeatMode mode) => switch (mode) {
  MusicRepeatMode.off => MusicRepeatMode.all,
  MusicRepeatMode.all => MusicRepeatMode.one,
  MusicRepeatMode.one => MusicRepeatMode.off,
};
