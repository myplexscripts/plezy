import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../services/settings_service.dart';
import 'platform_detector.dart';

/// Whether TV cards for movies, shows and episodes use 16:9 artwork
/// (Settings → Appearance → Card Style). Always false off TV.
bool tvLandscapeCards() {
  if (!PlatformDetector.isTV()) return false;
  final style = SettingsService.instanceOrNull?.read(SettingsService.tvCardStyle) ?? TvCardStyle.landscape;
  return style == TvCardStyle.landscape;
}

/// The card shape the Card Style setting gives [item], or null to keep its
/// natural shape. Music, photos, playlists, collections and people keep
/// theirs in both styles.
CardShape? tvCardShapeFor(MediaItem item, {required bool landscape}) {
  switch (item.kind) {
    case MediaKind.movie || MediaKind.show || MediaKind.season || MediaKind.episode:
      return landscape ? CardShape.wide : null;
    default:
      return null;
  }
}

/// Episode artwork under the Card Style setting: Posters shows an episode as
/// its season or series poster (the user's choice between those is kept),
/// never as a 16:9 still.
EpisodePosterMode tvEpisodePosterMode(EpisodePosterMode mode) {
  if (!PlatformDetector.isTV() || tvLandscapeCards()) return mode;
  return mode == EpisodePosterMode.episodeThumbnail ? EpisodePosterMode.seriesPoster : mode;
}
