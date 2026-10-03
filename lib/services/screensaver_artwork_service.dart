import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../media/catalog_item_ref.dart';
import '../media/ids.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';

/// Hands the Android TV screensaver (`ArtworkScreensaver`) a set of library
/// backdrops with their titles, refreshed whenever Home's hubs change.
class ScreensaverArtworkService {
  ScreensaverArtworkService._();

  static final ScreensaverArtworkService instance = ScreensaverArtworkService._();

  static const MethodChannel _channel = MethodChannel('com.plezy/screensaver');
  static const int _maxItems = 40;

  Timer? _debounce;
  String? _lastSignature;

  /// Publishes backdrops from [hubs] a moment after they settle.
  void publishFromHubs(List<MediaHub> hubs, MediaServerClient? Function(ServerId serverId) clientFor) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => unawaited(_publish(hubs, clientFor)));
  }

  Future<void> _publish(List<MediaHub> hubs, MediaServerClient? Function(ServerId serverId) clientFor) async {
    final seen = <String>{};
    final items = <Map<String, String>>[];
    for (final hub in hubs) {
      for (final item in hub.items) {
        if (items.length >= _maxItems) break;
        final entry = _entryFor(item, clientFor);
        if (entry != null && seen.add(entry['url']!)) items.add(entry);
      }
    }
    if (items.isEmpty) return;
    final signature = items.map((e) => e['url']).join('|');
    if (signature == _lastSignature) return;
    _lastSignature = signature;
    try {
      await _channel.invokeMethod<void>('setArtwork', {'items': items});
    } on MissingPluginException {
      // Not inside the Android activity.
    } catch (e) {
      appLogger.d('Screensaver artwork not published', error: e);
    }
  }

  Map<String, String>? _entryFor(MediaItem item, MediaServerClient? Function(ServerId) clientFor) {
    final serverId = item.serverId;
    if (serverId == null || item.isCatalogItem) return null;
    final isEpisode = item.kind == MediaKind.episode;
    final art = isEpisode ? (item.grandparentArtPath ?? item.artPath) : item.artPath;
    if (art == null || art.isEmpty) return null;
    final client = clientFor(ServerId(serverId));
    if (client == null) return null;
    return {
      'url': client.thumbnailUrl(art, width: 1920, height: 1080),
      'title': isEpisode ? (item.grandparentTitle ?? item.displayTitle) : item.displayTitle,
      'subtitle': [?item.year?.toString(), ?item.libraryTitle].join('  ·  '),
    };
  }
}
