import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/trailer_preview_service.dart';
import 'package:plezy/services/trailer_resolver.dart';
import 'package:plezy/utils/platform_detector.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

MediaItem _clip(String id, {String? extraType}) => testMediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.clip,
  title: id,
).copyWith(raw: {'ExtraType': ?extraType});

void main() {
  group('pickTrailer', () {
    final movie = testMediaItem(id: 'm', backend: MediaBackend.jellyfin, kind: MediaKind.movie, title: 'Movie');

    test('takes the first extra classified as a trailer', () {
      final picked = pickTrailer(movie, [_clip('bts', extraType: 'BehindTheScenes'), _clip('t', extraType: 'Trailer')]);
      expect(picked?.id, 't');
    });

    test('returns null when nothing is a trailer', () {
      expect(pickTrailer(movie, [_clip('bts', extraType: 'BehindTheScenes')]), isNull);
      expect(pickTrailer(movie, const []), isNull);
    });
  });

  group('TrailerPreviewService', () {
    setUp(() async {
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      await SettingsService.getInstance();
    });
    tearDown(() async {
      TvDetectionService.debugSetAppleTVOverride(null);
      await TrailerPreviewService.instance.stop();
    });

    MediaItem movie() => testMediaItem(id: 'm', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Movie');

    test('does nothing off TV, for non-movies, or while music plays', () {
      final service = TrailerPreviewService.instance;
      service.focus(movie(), null);
      expect(service.subject, isNull);

      TvDetectionService.debugSetAppleTVOverride(true);
      final episode = testMediaItem(id: 'e', backend: MediaBackend.plex, kind: MediaKind.episode, title: 'E');
      service.focus(episode, null);
      expect(service.subject, isNull);
      expect(service.isShowing, isFalse);
    });

    test('respects the Trailer Previews setting', () async {
      TvDetectionService.debugSetAppleTVOverride(true);
      await SettingsService.instance.write(SettingsService.trailerPreviews, false);
      TrailerPreviewService.instance.focus(movie(), null);
      expect(TrailerPreviewService.instance.subject, isNull);
    });
  });
}
