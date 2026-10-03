import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/screens/libraries/libraries_screen.dart';
import 'package:plezy/screens/photos/photo_album_screen.dart';
import 'package:plezy/services/plex_constants.dart';
import 'package:plezy/services/settings_service.dart';

void main() {
  group('photo items', () {
    test('a Jellyfin PhotoAlbum is an album, a Photo is a photo', () {
      final album = MediaItem(
        id: 'a',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.fromString('PhotoAlbum'),
        raw: const {'Type': 'PhotoAlbum'},
      );
      final photo = MediaItem(id: 'p', backend: MediaBackend.jellyfin, kind: MediaKind.photo);

      expect(album.isPhotoAlbum, isTrue);
      expect(album.isPhoto, isFalse);
      expect(photo.isPhoto, isTrue);
      expect(isPhotoViewerItem(photo), isTrue);
      expect(isPhotoViewerItem(album), isFalse);
    });

    test('a Plex photo directory (children key, no media) is an album', () {
      final album = MediaItem(
        id: '9',
        backend: MediaBackend.plex,
        kind: MediaKind.photo,
        raw: const {'key': '/library/metadata/9/children'},
      );
      expect(album.isPhotoAlbum, isTrue);
    });

    test('photos and albums use landscape cards', () {
      final photo = MediaItem(id: 'p', backend: MediaBackend.jellyfin, kind: MediaKind.photo);
      expect(photo.cardShape(EpisodePosterMode.seriesPoster), CardShape.wide);
    });

    test('Plex photo and clip type codes round-trip', () {
      expect(PlexMetadataType.forKind(MediaKind.photo), 13);
      expect(PlexMetadataType.kindFor(13), MediaKind.photo);
      expect(PlexMetadataType.kindFor(12), MediaKind.clip);
    });
  });

  test('photo libraries hide the collections tab', () {
    final library = MediaLibrary(
      id: '1',
      backend: MediaBackend.plex,
      title: 'Photos',
      kind: MediaKind.photo,
      hidden: false,
      isShared: false,
    );
    expect(visibleLibraryTabs(library), [LibraryTabType.recommended, LibraryTabType.browse, LibraryTabType.playlists]);
  });
}
