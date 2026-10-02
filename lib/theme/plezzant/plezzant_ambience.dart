import 'dart:async';

import 'package:flutter/widgets.dart';

import 'artwork_color_extractor.dart';
import 'plezzant_color_matcher.dart';
import 'plezzant_palette.dart';

/// App-wide contextual colour derived from whatever artwork currently has the
/// viewer's attention (the focused spotlight item, the open detail page, the
/// playing title).
///
/// The value is always a palette match (or null for neutral context), never a
/// raw extracted colour. Ambient gradients, focus tints and progress
/// indicators read it through [accent].
class PlezzantAmbience extends ValueNotifier<PlezzantColorMatch?> {
  PlezzantAmbience._() : super(null);

  static final PlezzantAmbience instance = PlezzantAmbience._();

  /// Focus can sweep across a row faster than artwork decodes; only the item
  /// the viewer settles on drives the ambience.
  static const Duration settleDelay = Duration(milliseconds: 220);

  Timer? _settle;
  String? _pendingKey;
  String? _currentKey;

  String? get currentKey => _currentKey;

  /// Request ambience from [provider], identified by [key] (usually the media
  /// item's global key plus artwork path). Cached keys apply immediately.
  void requestFromArtwork(String key, ImageProvider provider) {
    if (key == _currentKey || key == _pendingKey) return;
    _settle?.cancel();
    final extractor = ArtworkColorExtractor.instance;
    _pendingKey = key;
    if (extractor.hasCached(key)) {
      // Callers may request from build(); notifying listeners there would mark
      // widgets dirty mid-build, so even cached results land on the next tick.
      _settle = Timer(Duration.zero, () {
        if (_pendingKey != key) return;
        _pendingKey = null;
        _apply(key, extractor.cached(key));
      });
      return;
    }
    _settle = Timer(settleDelay, () async {
      final match = await extractor.extract(key, provider);
      if (_pendingKey != key) return;
      _pendingKey = null;
      _apply(key, match);
    });
  }

  /// Apply an already-known palette match (e.g. Live TV channel colour).
  void setMatch(String key, PlezzantColorMatch? match) {
    _settle?.cancel();
    _pendingKey = null;
    _apply(key, match);
  }

  void clear() {
    _settle?.cancel();
    _pendingKey = null;
    _currentKey = null;
    value = null;
  }

  void _apply(String key, PlezzantColorMatch? match) {
    _currentKey = key;
    value = match;
  }

  /// The palette colour for [shade] under the current ambience, falling back
  /// to the brand hue when the context is neutral.
  Color accent(PlezzantShade shade) => (value?.hue ?? PlezzantPalette.brand).shade(shade);

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }
}
