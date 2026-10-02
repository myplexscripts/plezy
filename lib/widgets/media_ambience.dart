import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../theme/plezzant/plezzant_ambience.dart';
import '../utils/media_image_helper.dart';

/// Points the app-wide palette ambience at [item]'s poster artwork.
///
/// Uses the series poster for episodes (stronger, more stable colour than an
/// episode still) and the smallest server-side transcode so extraction costs
/// one tiny request per settled focus. No-op without a client or artwork.
void requestAmbienceForItem(MediaItem? item, MediaServerClient? client) {
  if (item == null || client == null) return;
  final path = item.grandparentThumbPath ?? item.thumbPath ?? item.artPath;
  if (path == null || path.isEmpty) return;
  final url = client.thumbnailUrl(path, width: 160, height: 240);
  if (url.isEmpty) return;
  PlezzantAmbience.instance.requestFromArtwork(
    '${item.globalKey}|$path',
    MediaImageHelper.serverArtworkProvider(imageUrl: url, memWidth: 160, memHeight: 240),
  );
}
