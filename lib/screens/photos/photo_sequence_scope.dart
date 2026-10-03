import 'package:flutter/widgets.dart';

import '../../media/media_item.dart';

/// Gives the photo viewer the photos around the one that was opened, so left
/// and right step through the grid the viewer came from.
///
/// Photo grids (library "Photos" tab, album pages) wrap their content in this;
/// anywhere else (search, hubs) the viewer opens on the single photo.
class PhotoSequenceScope extends InheritedWidget {
  /// The grid's loaded items, in display order.
  final List<MediaItem> Function() items;

  const PhotoSequenceScope({super.key, required this.items, required super.child});

  static PhotoSequenceScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PhotoSequenceScope>();

  @override
  bool updateShouldNotify(PhotoSequenceScope oldWidget) => false;
}
