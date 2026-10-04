import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../services/settings_service.dart';
import 'platform_detector.dart';

/// Whether TV cards for movies and shows use 16:9 artwork
/// (Settings → Appearance → Card Style). Always false off TV.
bool tvLandscapeCards() {
  if (!PlatformDetector.isTV()) return false;
  final style = SettingsService.instanceOrNull?.read(SettingsService.tvCardStyle) ?? TvCardStyle.landscape;
  return style == TvCardStyle.landscape;
}

/// The card shape the Card Style setting gives [item], or null to keep its
/// natural shape. Episodes are always 16:9 on TV, whatever the style; music,
/// photos, playlists, collections and people keep theirs in both styles.
CardShape? tvCardShapeFor(MediaItem item, {required bool landscape}) {
  switch (item.kind) {
    case MediaKind.episode:
      return PlatformDetector.isTV() ? CardShape.wide : null;
    case MediaKind.movie || MediaKind.show || MediaKind.season:
      return landscape ? CardShape.wide : null;
    default:
      return null;
  }
}

/// Episode artwork on TV: always the episode's own 16:9 still, in every
/// Card Style and wherever an episode appears (rows, playlists, collections,
/// search, season rows).
EpisodePosterMode tvEpisodePosterMode(EpisodePosterMode mode) =>
    PlatformDetector.isTV() ? EpisodePosterMode.episodeThumbnail : mode;
