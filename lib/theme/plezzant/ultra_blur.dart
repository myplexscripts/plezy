import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../services/device_performance.dart';
import '../../utils/media_image_helper.dart';
import 'plezzant_tokens.dart';

/// The four corner colours of a Plex UltraBlur background.
@immutable
class UltraBlurColors {
  const UltraBlurColors(this.topLeft, this.topRight, this.bottomLeft, this.bottomRight);

  final Color topLeft;
  final Color topRight;
  final Color bottomLeft;
  final Color bottomRight;

  /// Calm default before any artwork resolves: the Plezzant night.
  static const fallback = UltraBlurColors(Color(0xFF1C1B2E), Color(0xFF26233D), Color(0xFF121220), Color(0xFF1A1830));

  List<Color> get corners => [topLeft, topRight, bottomLeft, bottomRight];

  /// Keeps every corner dark enough for white text, as Plex's own palette is.
  UltraBlurColors readable() => UltraBlurColors(_tame(topLeft), _tame(topRight), _tame(bottomLeft), _tame(bottomRight));

  static Color _tame(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(hsl.lightness.clamp(0.06, 0.34)).withSaturation(math.min(hsl.saturation, 0.72)).toColor();
  }

  static UltraBlurColors lerp(UltraBlurColors a, UltraBlurColors b, double t) => UltraBlurColors(
    Color.lerp(a.topLeft, b.topLeft, t)!,
    Color.lerp(a.topRight, b.topRight, t)!,
    Color.lerp(a.bottomLeft, b.bottomLeft, t)!,
    Color.lerp(a.bottomRight, b.bottomRight, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is UltraBlurColors &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomLeft == bottomLeft &&
      other.bottomRight == bottomRight;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomLeft, bottomRight);
}

/// Resolves the blur colours for titles by sampling their backdrop's edges
/// (see [UltraBlurResolver.fromEdges]). Results are memoised per art.
class UltraBlurResolver {
  UltraBlurResolver._();

  static final UltraBlurResolver instance = UltraBlurResolver._();

  static const int _cacheLimit = 200;
  final LinkedHashMap<String, UltraBlurColors?> _cache = LinkedHashMap();
  final Map<String, Future<UltraBlurColors?>> _inFlight = {};

  /// The backdrop UltraBlur reads for [item]: series art for episodes.
  static String? artPathFor(MediaItem item) {
    final paths = item.heroBackdropPaths;
    if (paths.isNotEmpty) return paths.first;
    if (item.kind == MediaKind.episode) return item.grandparentArtPath ?? item.grandparentThumbPath ?? item.thumbPath;
    return item.artPath ?? item.thumbPath;
  }

  static String keyFor(MediaServerClient client, String path) => '${client.serverId}|$path';

  bool hasCached(String key) => _cache.containsKey(key);
  UltraBlurColors? cached(String key) => _cache[key];

  Future<UltraBlurColors?> resolve(MediaServerClient client, String path) {
    final key = keyFor(client, path);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    return _inFlight[key] ??= _resolve(client, path)
        .then((colors) {
          _cache[key] = colors;
          while (_cache.length > _cacheLimit) {
            _cache.remove(_cache.keys.first);
          }
          return colors;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });
  }

  /// Samples the backdrop's left side, bottom-left corner and bottom edge:
  /// the edges the blur has to melt into.
  Future<UltraBlurColors?> _resolve(MediaServerClient client, String path) async {
    final url = client.thumbnailUrl(path, width: 96, height: 54);
    if (url.isEmpty) return null;
    final provider = MediaImageHelper.serverArtworkProvider(imageUrl: url, memWidth: 48, memHeight: 27);
    final image = await _decode(ResizeImage(provider, width: 48, height: 27, policy: ResizeImagePolicy.exact));
    if (image == null) return null;
    final (pixels, width, height) = image;
    return fromEdges(pixels, width, height)?.readable();
  }

  /// The blur field for RGBA [pixels]: the left side colours the top and
  /// left, the bottom-left corner the lower left, the bottom edge the lower
  /// right — so the field is continuous with the artwork's own edges.
  @visibleForTesting
  static UltraBlurColors? fromEdges(Uint8List pixels, int width, int height) {
    if (width < 4 || height < 4 || pixels.length < width * height * 4) return null;
    Color average(bool Function(double x, double y) inside) {
      var r = 0.0, g = 0.0, b = 0.0, n = 0.0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (!inside(x / (width - 1), y / (height - 1))) continue;
          final i = (y * width + x) * 4;
          r += pixels[i];
          g += pixels[i + 1];
          b += pixels[i + 2];
          n++;
        }
      }
      if (n == 0) return const Color(0xFF000000);
      return Color.fromARGB(255, (r / n).round(), (g / n).round(), (b / n).round());
    }

    final left = average((x, y) => x <= 0.14);
    final bottomLeft = average((x, y) => x <= 0.28 && y >= 0.72);
    final bottom = average((x, y) => y >= 0.86);
    return UltraBlurColors(left, left, bottomLeft, bottom);
  }

  static Future<(Uint8List, int, int)?> _decode(ImageProvider provider) {
    final completer = Completer<(Uint8List, int, int)?>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) async {
        try {
          final data = await info.image.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (!completer.isCompleted) {
            completer.complete(data == null ? null : (data.buffer.asUint8List(), info.image.width, info.image.height));
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        } finally {
          info.dispose();
          stream.removeListener(listener);
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
}

/// The UltraBlur behind whatever title has the viewer's attention.
class UltraBlurAmbience extends ValueNotifier<UltraBlurColors?> {
  UltraBlurAmbience._() : super(null);

  static final UltraBlurAmbience instance = UltraBlurAmbience._();

  /// Focus sweeps faster than requests land; only a settled title asks.
  static const Duration settleDelay = Duration(milliseconds: 240);

  Timer? _settle;
  String? _pendingKey;
  String? _currentKey;

  /// Point the background at [item]. Cached colours land on the next tick
  /// (callers may be building); others after [settleDelay].
  void request(MediaItem? item, MediaServerClient? client) {
    if (item == null || client == null) return;
    final path = UltraBlurResolver.artPathFor(item);
    if (path == null || path.isEmpty) return;
    final key = UltraBlurResolver.keyFor(client, path);
    if (key == _currentKey || key == _pendingKey) return;
    _settle?.cancel();
    _pendingKey = key;
    final resolver = UltraBlurResolver.instance;
    _settle = Timer(resolver.hasCached(key) ? Duration.zero : settleDelay, () async {
      final colors = await resolver.resolve(client, path);
      if (_pendingKey != key) return;
      _pendingKey = null;
      _currentKey = key;
      if (colors != null) value = colors;
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }
}

/// Full-bleed Plex UltraBlur: four corner colours blended into a soft field,
/// with a fine grain so the gradient never bands on 8-bit TV panels.
/// Colour changes cross-fade.
class UltraBlurBackground extends StatelessWidget {
  const UltraBlurBackground({super.key, this.colors});

  /// Fixed colours; null follows [UltraBlurAmbience].
  final UltraBlurColors? colors;

  @override
  Widget build(BuildContext context) {
    final fixed = colors;
    if (fixed != null) return _animated(fixed);
    return ValueListenableBuilder<UltraBlurColors?>(
      valueListenable: UltraBlurAmbience.instance,
      builder: (context, value, _) => _animated(value ?? UltraBlurColors.fallback),
    );
  }

  Widget _animated(UltraBlurColors target) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<UltraBlurColors>(
        tween: _UltraBlurTween(end: target),
        duration: DevicePerformance.reducedDuration(PlezzantMotion.ambience),
        curve: PlezzantMotion.standard,
        builder: (context, value, _) => CustomPaint(painter: UltraBlurPainter(value), child: const SizedBox.expand()),
      ),
    );
  }
}

class _UltraBlurTween extends Tween<UltraBlurColors> {
  _UltraBlurTween({super.end});

  @override
  UltraBlurColors lerp(double t) => UltraBlurColors.lerp(begin ?? end!, end!, t);
}

/// Paints [colors] as a smooth bilinear field over a vertex grid, eased so
/// the corners bloom into each other like Plex's UltraBlur, plus grain.
class UltraBlurPainter extends CustomPainter {
  UltraBlurPainter(this.colors);

  final UltraBlurColors colors;

  static const int _grid = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final positions = <Offset>[];
    final vertexColors = <Color>[];
    for (var j = 0; j <= _grid; j++) {
      for (var i = 0; i <= _grid; i++) {
        final u = i / _grid, v = j / _grid;
        positions.add(Offset(u * size.width, v * size.height));
        vertexColors.add(_at(_ease(u), _ease(v)));
      }
    }
    final indices = <int>[];
    for (var j = 0; j < _grid; j++) {
      for (var i = 0; i < _grid; i++) {
        final a = j * (_grid + 1) + i, b = a + 1, c = a + _grid + 1, d = c + 1;
        indices.addAll([a, b, c, b, d, c]);
      }
    }
    final vertices = ui.Vertices(VertexMode.triangles, positions, colors: vertexColors, indices: indices);
    canvas.drawVertices(vertices, BlendMode.dst, Paint());
    final grain = _Grain.image;
    if (grain != null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ImageShader(grain, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage)
          ..blendMode = BlendMode.overlay,
      );
    } else {
      _Grain.ensure();
    }
  }

  static double _ease(double t) => t * t * (3 - 2 * t);

  Color _at(double u, double v) {
    final top = Color.lerp(colors.topLeft, colors.topRight, u)!;
    final bottom = Color.lerp(colors.bottomLeft, colors.bottomRight, u)!;
    return Color.lerp(top, bottom, v)!;
  }

  @override
  bool shouldRepaint(UltraBlurPainter oldDelegate) => oldDelegate.colors != colors;
}

/// A tiny tile of neutral grain, made once.
abstract final class _Grain {
  static ui.Image? image;
  static bool _started = false;

  static void ensure() {
    if (_started) return;
    _started = true;
    const size = 96;
    final rnd = math.Random(7);
    final pixels = Uint8List(size * size * 4);
    for (var i = 0; i < size * size; i++) {
      final v = 118 + rnd.nextInt(21);
      pixels[i * 4] = v;
      pixels[i * 4 + 1] = v;
      pixels[i * 4 + 2] = v;
      pixels[i * 4 + 3] = 22;
    }
    ui.decodeImageFromPixels(pixels, size, size, ui.PixelFormat.rgba8888, (img) => image = img);
  }
}
