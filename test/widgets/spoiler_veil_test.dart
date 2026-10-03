import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/widgets/spoiler_veil.dart';

import '../test_helpers/media_items.dart';

void main() {
  test('labels an episode by season and number, anything else by title', () {
    final episode = testMediaItem(
      id: 'e',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Night Ferry',
    ).copyWith(parentIndex: 2, index: 5);
    expect(SpoilerVeil.labelFor(episode), 'S2 E5');
    final movie = testMediaItem(id: 'm', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Cobalt');
    expect(SpoilerVeil.labelFor(movie), 'Cobalt');
  });

  testWidgets('a veiled tile still says which episode it is', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 160,
            height: 90,
            child: SpoilerVeil(
              label: 'S1 E3',
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );
    expect(find.text('S1 E3'), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
  });
}
