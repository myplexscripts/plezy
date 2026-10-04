import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';

/// Picks [item]'s trailer from its [extras]: Plex's primary extra when it
/// names one, else the first extra classified as a trailer.
MediaItem? pickTrailer(MediaItem item, List<MediaItem> extras) {
  if (extras.isEmpty) return null;
  if (item case PlexMediaItem(:final trailerKey?)) {
    final primaryKey = trailerKey.split('/').last;
    for (final extra in extras) {
      if (extra.id == primaryKey) return extra;
    }
  }
  for (final extra in extras) {
    if (isTrailerExtra(extra)) return extra;
  }
  return null;
}

/// Whether [extra] is a trailer (Plex `subtype`, Jellyfin `ExtraType`/`Type`).
bool isTrailerExtra(MediaItem extra) {
  if (extra case PlexMediaItem(:final subtype?)) {
    return subtype.toLowerCase() == 'trailer';
  }
  final raw = extra.raw;
  final extraType = raw?['ExtraType'] as String?;
  final type = raw?['Type'] as String?;
  return extraType?.toLowerCase() == 'trailer' || type?.toLowerCase() == 'trailer';
}

/// Looks up and remembers titles' trailers for the focus previews, so moving
/// back and forth along a row costs one extras request per title.
class TrailerResolver {
  TrailerResolver._();

  static final TrailerResolver instance = TrailerResolver._();
  static const int _maxEntries = 120;

  final Map<String, Future<MediaItem?>> _cache = {};

  Future<MediaItem?> trailerFor(MediaItem item, MediaServerClient client) {
    // An episode previews its series' trailer (Continue Watching rows).
    final seriesId = item.kind == MediaKind.episode ? item.grandparentId : null;
    if (item.kind != MediaKind.movie && item.kind != MediaKind.show && seriesId == null) return Future.value();
    final extrasId = seriesId ?? item.id;
    final key = seriesId == null ? item.globalKey : '${item.serverId}:$seriesId';
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    final future = client.fetchExtras(extrasId).then<MediaItem?>((extras) => pickTrailer(item, extras)).catchError((
      Object e,
    ) {
      appLogger.d('Trailer lookup failed for ${item.displayTitle}', error: e);
      return null;
    });
    _cache[key] = future;
    if (_cache.length > _maxEntries) _cache.remove(_cache.keys.first);
    return future;
  }
}
