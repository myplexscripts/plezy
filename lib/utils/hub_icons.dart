import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../media/media_hub.dart';

/// Minimal Lucide icon treatment for media shelves. Artwork and typography
/// carry the visual hierarchy, while shelf icons stay quiet and consistent.
IconData hubIconFor(MediaHub hub) {
  final title = hub.title.toLowerCase();

  if (hub.isContinueWatchingHub || title.contains('continue watching') || title.contains('on deck')) {
    return LucideIcons.circle_play;
  }
  if (title.contains('trending') || title.contains('popular')) return LucideIcons.flame;
  if (title.contains('recent') || title.contains('new release') || title.contains('newly')) {
    return LucideIcons.clock;
  }
  if (title.contains('rated') || title.contains('top ')) return LucideIcons.star;
  if (title.contains('recommended')) return LucideIcons.thumbs_up;
  if (title.contains('playlist') || title.contains('watchlist')) return LucideIcons.list_video;
  if (title.contains('actor') || title.contains('director')) return LucideIcons.user;
  if (title.contains('network') || title.contains('more from')) return LucideIcons.tv;
  if (title.contains('genre')) return LucideIcons.shapes;

  return LucideIcons.sparkles;
}
