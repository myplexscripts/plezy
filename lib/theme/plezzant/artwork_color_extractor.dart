import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../utils/app_logger.dart';
import 'plezzant_color_matcher.dart';

/// Pulls one representative colour out of artwork and snaps it onto the
/// Plezzant palette.
///
/// Artwork is decoded at a tiny size ([sampleWidth] pixels wide) so extraction
/// never allocates a full-resolution bitmap, and results are memoised per
/// artwork key so revisiting a title costs nothing.
class ArtworkColorExtractor {
  ArtworkColorExtractor._();

  static final ArtworkColorExtractor instance = ArtworkColorExtractor._();

  static const int sampleWidth = 40;
  static const int _cacheLimit = 256;

  final LinkedHashMap<String, PlezzantColorMatch?> _cache = LinkedHashMap();
  final Map<String, Future<PlezzantColorMatch?>> _inFlight = {};

  /// Cached result for [key], or null when unknown. A cached neutral result is
  /// also null; use [hasCached] to tell the two apart.
  PlezzantColorMatch? cached(String key) => _cache[key];

  bool hasCached(String key) => _cache.containsKey(key);

  /// Extract and palette-match the dominant colour of [provider].
  ///
  /// Returns null for neutral (grey/black/white) artwork or when decoding
  /// fails; callers fall back to neutral ambience.
  Future<PlezzantColorMatch?> extract(String key, ImageProvider provider) {
    if (_cache.containsKey(key)) {
      final value = _cache.remove(key);
      _cache[key] = value; // refresh LRU position
      return Future.value(value);
    }
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _decode(ResizeImage(provider, width: sampleWidth, policy: ResizeImagePolicy.fit))
        .then((pixels) {
          final match = pixels == null ? null : PlezzantColorMatcher.matchOrNull(dominantColor(pixels));
          _remember(key, match);
          return match;
        })
        .catchError((Object e) {
          appLogger.d('Artwork colour extraction failed for $key', error: e);
          return null;
        })
        .whenComplete(() => _inFlight.remove(key));
    _inFlight[key] = future;
    return future;
  }

  void _remember(String key, PlezzantColorMatch? match) {
    _cache[key] = match;
    while (_cache.length > _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
  }

  static Future<Uint8List?> _decode(ImageProvider provider) {
    final completer = Completer<Uint8List?>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) async {
        stream.removeListener(listener);
        try {
          final data = await info.image.toByteData(format: ui.ImageByteFormat.rawRgba);
          completer.complete(data?.buffer.asUint8List());
        } catch (e) {
          completer.complete(null);
        } finally {
          info.dispose();
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  /// The visually dominant colour of raw RGBA [pixels].
  ///
  /// Pixels are bucketed on a 4-bit-per-channel grid and weighted toward
  /// saturated, mid-luminance colour, so a small but vivid subject beats a
  /// large dark or blown-out background. Returns the weighted mean of the
  /// winning bucket, or null when every pixel is transparent.
  static Color? dominantColor(Uint8List pixels) {
    final weights = <int, double>{};
    final sums = <int, List<double>>{};
    for (var i = 0; i + 3 < pixels.length; i += 4) {
      if (pixels[i + 3] < 128) continue;
      final r = pixels[i], g = pixels[i + 1], b = pixels[i + 2];
      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
      final sat = maxC == 0 ? 0.0 : (maxC - minC) / maxC;
      // Bell-shaped luminance weight: near-black and near-white pixels carry
      // little colour information and would otherwise dominate posters.
      final lumWeight = math.exp(-math.pow((lum - 0.5) / 0.28, 2));
      final weight = (0.08 + sat * sat) * lumWeight;
      final key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
      weights[key] = (weights[key] ?? 0) + weight;
      final sum = sums.putIfAbsent(key, () => [0, 0, 0]);
      sum[0] += r * weight;
      sum[1] += g * weight;
      sum[2] += b * weight;
    }
    if (weights.isEmpty) return null;
    var bestKey = weights.keys.first;
    var bestWeight = -1.0;
    weights.forEach((key, w) {
      if (w > bestWeight) {
        bestWeight = w;
        bestKey = key;
      }
    });
    final sum = sums[bestKey]!;
    if (bestWeight <= 0) {
      return Color.fromARGB(0xFF, (bestKey >> 8) << 4, ((bestKey >> 4) & 0xF) << 4, (bestKey & 0xF) << 4);
    }
    return Color.fromARGB(
      0xFF,
      (sum[0] / bestWeight).round().clamp(0, 255),
      (sum[1] / bestWeight).round().clamp(0, 255),
      (sum[2] / bestWeight).round().clamp(0, 255),
    );
  }
}
