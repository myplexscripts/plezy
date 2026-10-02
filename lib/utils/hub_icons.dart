import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../media/media_hub.dart';

/// Leading icon for a hub row, shared by every surface that renders hubs from
/// the same backend rows (Discover and a library's Recommended tab).
///
/// Continue Watching is matched on the hub key first so synthesized rows and
/// section-specific `*.inprogress.*` hubs are covered, then on title for
/// backends whose resume row is only recognizable by name (Plex "On Deck").
/// Everything else is keyword-matched on the title; the first match wins, so
/// the more specific keywords are checked before the broader ones.
IconData hubIconFor(MediaHub hub) {
  final title = hub.title.toLowerCase();

  if (hub.isContinueWatchingHub || title.contains('continue watching') || title.contains('on deck')) {
    return LucideIcons.circlePlay;
  }
  for (final (keywords, icon) in _titleKeywordIcons) {
    if (keywords.any(title.contains)) return icon;
  }
  return _defaultHubIcon;
}

const _defaultHubIcon = LucideIcons.sparkles;

/// Title keywords in match order — see [hubIconFor].
const _titleKeywordIcons = <(List<String>, IconData)>[
  // Trending/Popular
  (['trending'], LucideIcons.trendingUp),
  (['popular', 'imdb'], LucideIcons.flame),
  // Seasonal/Time-based
  (['seasonal'], LucideIcons.calendarDays),
  (['newly', 'new release'], LucideIcons.badgeAlert),
  (['recently released', 'recent'], LucideIcons.clock),
  // Top/Rated
  (['top rated', 'highest rated'], LucideIcons.star),
  (['top '], LucideIcons.medal),
  // Genre-specific
  (['thriller'], LucideIcons.triangleAlert),
  (['comedy', 'comedier'], LucideIcons.smile),
  (['action'], LucideIcons.zap),
  (['drama'], LucideIcons.drama),
  (['fantasy'], LucideIcons.wandSparkles),
  (['science', 'sci-fi'], LucideIcons.rocket),
  (['horror', 'skräck'], LucideIcons.moonStar),
  (['romance', 'romantic'], LucideIcons.heart),
  (['adventure', 'äventyr'], LucideIcons.compass),
  // Watchlist/Playlists
  (['playlist', 'watchlist'], LucideIcons.listVideo),
  (['unwatched', 'unplayed'], LucideIcons.eyeOff),
  (['watched', 'played'], LucideIcons.eye),
  // Network/Studio
  (['network', 'more from'], LucideIcons.tv),
  // Actor/Director
  (['actor', 'director'], LucideIcons.user),
  // Decades (80s, 90s, etc.)
  (['80', '90', '00'], LucideIcons.history),
  // Rediscover/Start Watching
  (['rediscover', 'start watching'], LucideIcons.play),
  // Broad library-hub keywords, last so the specific rows above keep their icons.
  (['rated'], LucideIcons.star),
  (['recommended'], LucideIcons.thumbsUp),
  (['genre'], LucideIcons.shapes),
];
