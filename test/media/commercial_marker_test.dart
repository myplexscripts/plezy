import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/services/plex_mappers.dart';

void main() {
  test('Plex commercial markers are parsed as commercials', () {
    final markers = plexMarkersFromCacheJson({
      'Marker': [
        {'id': 1, 'type': 'intro', 'startTimeOffset': 0, 'endTimeOffset': 30000},
        {'id': 2, 'type': 'commercial', 'startTimeOffset': 600000, 'endTimeOffset': 780000},
      ],
    });

    expect(markers.map((m) => m.type), ['intro', 'commercial']);
    expect(markers[1].isCommercial, isTrue);
    expect(markers[1].isIntro, isFalse);
    expect(markers[1].isCredits, isFalse);
  });

  test('chapter fallback keeps commercial markers as they are', () {
    final extras = PlaybackExtras.withChapterFallback(
      chapters: const [],
      markers: [MediaMarker(id: 2, type: 'commercial', startTimeOffset: 600000, endTimeOffset: 780000)],
    );

    expect(extras.markers.single.isCommercial, isTrue);
  });
}
