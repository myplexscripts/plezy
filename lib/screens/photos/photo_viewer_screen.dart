import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../services/device_performance.dart';
import '../../services/settings_service.dart';
import '../../theme/plezzant/plezzant_glass.dart';
import '../../theme/plezzant/plezzant_tokens.dart';
import '../../theme/plezzant/plezzant_typography.dart';
import '../../utils/formatters.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/video_player_navigation.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/tv_reference_scale.dart';

/// Full-screen photo viewer with a slideshow, like the official apps.
///
/// LEFT / RIGHT step through [items], SELECT starts or pauses the slideshow
/// (or plays a video), UP / DOWN show the info panel, BACK closes.
class PhotoViewerScreen extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;
  final MediaServerClient? client;
  final bool startSlideshow;

  const PhotoViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.client,
    this.startSlideshow = false,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  static const Duration _infoAutoHide = Duration(seconds: 4);

  late int _index = widget.initialIndex.clamp(0, widget.items.length - 1);
  late bool _playing = widget.startSlideshow;
  bool _infoVisible = true;
  Timer? _slideTimer;
  Timer? _infoTimer;
  final FocusNode _focusNode = FocusNode(debugLabel: 'photo_viewer');

  MediaItem get _current => widget.items[_index];

  Duration get _interval => Duration(seconds: SettingsService.instance.read(SettingsService.photoSlideshowSeconds));

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    _scheduleInfoHide();
    if (_playing) _armSlideshow();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _infoTimer?.cancel();
    _focusNode.dispose();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  bool _isVideo(MediaItem item) => item.kind == MediaKind.clip || item.kind == MediaKind.movie;

  void _go(int delta, {bool fromSlideshow = false}) {
    if (widget.items.length < 2) return;
    var next = _index + delta;
    if (fromSlideshow) {
      next %= widget.items.length;
      // The slideshow skips videos rather than stalling on them.
      var guard = widget.items.length;
      while (_isVideo(widget.items[next]) && guard-- > 0) {
        next = (next + 1) % widget.items.length;
      }
    } else if (next < 0 || next >= widget.items.length) {
      return;
    }
    setState(() => _index = next);
    if (!fromSlideshow) {
      _showInfo();
      if (_playing) _armSlideshow();
    }
  }

  void _armSlideshow() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(_interval, (_) {
      if (mounted) _go(1, fromSlideshow: true);
    });
  }

  void _toggleSlideshow() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _armSlideshow();
      _hideInfo();
    } else {
      _slideTimer?.cancel();
      _showInfo();
    }
  }

  void _showInfo() {
    setState(() => _infoVisible = true);
    _scheduleInfoHide();
  }

  void _hideInfo() {
    _infoTimer?.cancel();
    setState(() => _infoVisible = false);
  }

  void _scheduleInfoHide() {
    _infoTimer?.cancel();
    _infoTimer = Timer(_infoAutoHide, () {
      if (mounted && _playing) setState(() => _infoVisible = false);
    });
  }

  Future<void> _activate() async {
    final item = _current;
    if (_isVideo(item)) {
      _slideTimer?.cancel();
      setState(() => _playing = false);
      await navigateToVideoPlayer(context, metadata: item);
      return;
    }
    _toggleSlideshow();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event.logicalKey.isBackKey) return handleBackKeyNavigation(context, event);
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.mediaTrackNext) {
      _go(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.mediaTrackPrevious) {
      _go(-1);
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.ignored;
    if (key.isSelectKey || key == LogicalKeyboardKey.mediaPlayPause || key == LogicalKeyboardKey.mediaPlay) {
      unawaited(_activate());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPause && _playing) {
      _toggleSlideshow();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.info) {
      _infoVisible ? _hideInfo() : _showInfo();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The original image for a photo (Plex keeps it on the media part; the
  /// Jellyfin primary image is the photo itself), else its thumbnail.
  static String? _fullImagePath(MediaItem item) {
    if (item.kind == MediaKind.photo) {
      for (final version in item.mediaVersions ?? const []) {
        for (final part in version.parts) {
          final path = part.streamPath;
          if (path != null && path.isNotEmpty) return path;
        }
      }
    }
    return item.thumbPath ?? item.artPath;
  }

  Widget _image(MediaItem item, Size size) => OptimizedMediaImage(
    client: widget.client,
    imagePath: _fullImagePath(item),
    imageType: ImageType.photo,
    width: size.width,
    height: size.height,
    fit: BoxFit.contain,
    fadeInDuration: Duration.zero,
    fallbackIcon: LucideIcons.image,
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final item = _current;
    final kenBurns = _playing && !DevicePerformance.isReduced && !DevicePerformance.reduceMotion;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activate,
          onHorizontalDragEnd: (d) => _go((d.primaryVelocity ?? 0) < 0 ? 1 : -1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Neighbours decode ahead of time so stepping is instant.
              for (final offset in const [-1, 1])
                if (_index + offset >= 0 && _index + offset < widget.items.length)
                  Offstage(child: _image(widget.items[_index + offset], size)),
              AnimatedSwitcher(
                duration: DevicePerformance.reducedDuration(const Duration(milliseconds: 700)),
                switchInCurve: PlezzantMotion.standard,
                switchOutCurve: PlezzantMotion.exit,
                child: KeyedSubtree(
                  key: ValueKey(item.globalKey),
                  child: kenBurns
                      ? TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 1.06),
                          duration: _interval + const Duration(milliseconds: 700),
                          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                          child: _image(item, size),
                        )
                      : _image(item, size),
                ),
              ),
              if (_isVideo(item)) const Center(child: _PlayBadge()),
              AnimatedOpacity(
                opacity: _infoVisible ? 1 : 0,
                duration: DevicePerformance.reducedDuration(PlezzantMotion.reveal),
                curve: PlezzantMotion.standard,
                child: IgnorePointer(
                  child: TvReferenceScale(
                    child: _InfoPanel(
                      item: item,
                      position: '${_index + 1} / ${widget.items.length}',
                      playing: _playing,
                      isVideo: _isVideo(item),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return const PlezzantGlass(
      style: PlezzantGlassStyle.overlay,
      borderRadius: BorderRadius.all(Radius.circular(PlezzantRadius.pill)),
      padding: EdgeInsets.all(20),
      child: AppIcon(LucideIcons.play, fill: 1, size: 36, color: Colors.white),
    );
  }
}

/// Bottom glass panel on the reference canvas: title, date and album, the
/// position in the sequence, and what SELECT does.
class _InfoPanel extends StatelessWidget {
  final MediaItem item;
  final String position;
  final bool playing;
  final bool isVideo;

  const _InfoPanel({required this.item, required this.position, required this.playing, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    final date = item.originallyAvailableAt;
    final details = [
      if (date != null && date.isNotEmpty) formatFullDate(date),
      if (item.parentTitle != null && item.parentTitle!.isNotEmpty) item.parentTitle!,
    ].join('  ·  ');
    final hint = isVideo
        ? t.photos.selectToPlay
        : playing
        ? t.photos.selectToPause
        : t.photos.selectForSlideshow;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(PlezzantTv.safeX, 0, PlezzantTv.safeX, PlezzantTv.safeY),
        child: PlezzantGlass(
          style: PlezzantGlassStyle.overlay,
          borderRadius: const BorderRadius.all(Radius.circular(PlezzantRadius.panel)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PlezzantTvType.cardTitle.copyWith(color: Colors.white),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PlezzantTvType.cardSubtitle.copyWith(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(position, style: PlezzantTvType.metadata.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        playing && !isVideo ? LucideIcons.pause : LucideIcons.play,
                        fill: 1,
                        size: 20,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(hint, style: PlezzantTvType.cardSubtitle.copyWith(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
