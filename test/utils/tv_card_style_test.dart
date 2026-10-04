import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/tv_card_style.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(true);
  });
  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  MediaItem item(MediaKind kind) => testMediaItem(id: kind.id, backend: MediaBackend.plex, kind: kind, title: 'x');

  test('landscape is the TV default and reshapes only video items', () {
    expect(tvLandscapeCards(), isTrue);
    for (final kind in [MediaKind.movie, MediaKind.show, MediaKind.season]) {
      expect(tvCardShapeFor(item(kind), landscape: true), CardShape.wide);
      expect(tvCardShapeFor(item(kind), landscape: false), isNull);
    }
    for (final kind in [MediaKind.album, MediaKind.artist, MediaKind.photo, MediaKind.collection]) {
      expect(tvCardShapeFor(item(kind), landscape: true), isNull);
    }
  });

  test('episodes are always 16:9, in every style', () async {
    expect(tvCardShapeFor(item(MediaKind.episode), landscape: true), CardShape.wide);
    expect(tvCardShapeFor(item(MediaKind.episode), landscape: false), CardShape.wide);
    await SettingsService.instance.write(SettingsService.tvCardStyle, TvCardStyle.poster);
    expect(tvLandscapeCards(), isFalse);
    for (final mode in EpisodePosterMode.values) {
      expect(tvEpisodePosterMode(mode), EpisodePosterMode.episodeThumbnail);
    }
  });

  test('off TV the setting does nothing', () {
    TvDetectionService.debugSetAppleTVOverride(false);
    expect(tvLandscapeCards(), isFalse);
    expect(tvEpisodePosterMode(EpisodePosterMode.episodeThumbnail), EpisodePosterMode.episodeThumbnail);
  });
}
