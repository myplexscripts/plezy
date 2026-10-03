import '../utils/video_player_navigation.dart';
import '../services/trailer_preview_service.dart';
import '../services/music/music_playback_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/strings.g.dart';
import '../media/catalog_item_ref.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../models/catalog/catalog_item.dart';
import '../navigation/main_screen_scope.dart';
import '../services/settings_service.dart';
import '../utils/debouncer.dart';
import '../utils/layout_constants.dart';
import '../theme/plezzant/plezzant_tokens.dart';
import '../utils/formatters.dart';
import 'tv_reference_scale.dart';
import 'tv_browse_rail.dart';
import 'tv_spotlight_background.dart';

class TvSpotlightController extends ValueNotifier<MediaItem?> {
  TvSpotlightController({Duration settleDelay = const Duration(milliseconds: 150)})
    : _settleDelay = settleDelay,
      _debouncer = Debouncer(settleDelay),
      super(null);

  final Duration _settleDelay;
  final Debouncer _debouncer;
  bool _playsDirectly = false;

  /// Whether pressing OK on the spotlit item starts playback (Continue
  /// Watching) rather than opening its details.
  bool get playsDirectly => _playsDirectly;

  void select(MediaItem item, {bool? playsDirectly}) {
    void apply() {
      final flagChanged = playsDirectly != null && playsDirectly != _playsDirectly;
      if (playsDirectly != null) _playsDirectly = playsDirectly;
      if (value?.globalKey == item.globalKey) {
        if (flagChanged) notifyListeners();
        return;
      }
      value = item;
    }

    if (_settleDelay == Duration.zero) {
      apply();
    } else {
      _debouncer.run(apply);
    }
  }

  MediaItem? resolve(Iterable<MediaHub> hubs) {
    MediaItem? fallback;
    final current = value;
    for (final hub in hubs) {
      if (hub.items.isEmpty) continue;
      fallback ??= hub.items.first;
      if (current == null) continue;
      for (final item in hub.items) {
        if (item.globalKey == current.globalKey) return item;
      }
    }
    return fallback;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

typedef TvSpotlightClientResolver = MediaServerClient? Function(MediaItem? item);

/// Shared full-screen TV backdrop and foreground stack used by hub rails.
class TvSpotlightScaffold extends StatelessWidget {
  const TvSpotlightScaffold({
    super.key,
    required this.hubs,
    required this.spotlightListenable,
    required this.resolveSpotlight,
    required this.resolveClient,
    required this.foreground,
    this.hideSpoilers,
    this.forceWideRailLayout = false,
    this.showActionHint = false,
  });

  final List<MediaHub> hubs;
  final ValueListenable<MediaItem?> spotlightListenable;
  final MediaItem? Function() resolveSpotlight;
  final TvSpotlightClientResolver resolveClient;
  final Widget foreground;
  final bool? hideSpoilers;
  final bool forceWideRailLayout;

  /// Apple TV style: a white pill under the synopsis naming what OK does on
  /// the focused card. Needs a [TvSpotlightController] as the listenable.
  final bool showActionHint;

  static (String, IconData?)? _actionFor(MediaItem? item, ValueListenable<MediaItem?> listenable) {
    if (item == null || listenable is! TvSpotlightController) return null;
    if (listenable.playsDirectly) {
      final inProgress = (item.viewOffsetMs ?? 0) > 0;
      return (inProgress ? t.common.resume : t.common.play, LucideIcons.play);
    }
    if (item.isShow || item.isSeason) return (t.discover.goToShow, null);
    if (item.isMovie) return (t.discover.goToMovie, null);
    if (item.isPhoto) return (t.photos.viewPhoto, LucideIcons.image);
    if (item.isPhotoAlbum) return (t.photos.openAlbum, LucideIcons.images);
    return (t.mediaMenu.viewDetails, null);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final settings = SettingsService.instance;
    final scale = TvLayoutConstants.scaleForSize(size);
    final railSize = MainScreenFocusScope.foregroundSizeOf(context);
    final fullBleedWidth = MainScreenFocusScope.fullBleedWidthOf(context);
    final railHeight = hubs.isEmpty
        ? 0.0
        : TvBrowseRailLayout.estimateHeight(
            size: railSize,
            hubs: hubs,
            density: settings.read(SettingsService.libraryDensity),
            episodePosterMode: settings.read(SettingsService.episodePosterMode),
            fullCardLayout: settings.read(SettingsService.tvFullCardLayout),
            gridSpacing: settings.read(SettingsService.gridSpacing),
            tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
            forceWideLayout: forceWideRailLayout,
          );
    final spotlightTop = PlezzantTv.safeY * scale;
    final minimumSpotlightBottom = railHeight + (8 * scale);
    final baseSpotlightBottom = size.height * 0.48;
    final desiredSpotlightBottom = minimumSpotlightBottom > baseSpotlightBottom
        ? minimumSpotlightBottom
        : baseSpotlightBottom;
    final maxSpotlightBottom = (size.height - spotlightTop - (PlezzantTv.safeY * scale))
        .clamp(0.0, double.infinity)
        .toDouble();
    final spotlightBottom = desiredSpotlightBottom > maxSpotlightBottom ? maxSpotlightBottom : desiredSpotlightBottom;
    final spotlightLeft = PlezzantTv.safeX * scale;

    final material = ListenableBuilder(
      listenable: TrailerPreviewService.instance,
      // A previewing trailer plays on the native surface beneath the UI, so
      // this surface clears while it shows; the hero scrims stay on top.
      builder: (context, child) => Material(
        color: TrailerPreviewService.instance.isShowing
            ? Colors.transparent
            : Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Builder(
              builder: (context) {
                final foregroundLeft = MainScreenFocusScope.foregroundLeftOf(context);
                final heroContentLeft = foregroundLeft > spotlightLeft
                    ? foregroundLeft + (PlezzantSpace.lg * scale)
                    : spotlightLeft;
                return SideNavigationBleedBuilder(
                  targetBleed: foregroundLeft,
                  child: ValueListenableBuilder<MediaItem?>(
                    valueListenable: spotlightListenable,
                    builder: (context, _, _) {
                      final spotlight = resolveSpotlight();
                      return _CatalogSpotlightBackground(
                        item: spotlight,
                        action: showActionHint ? _actionFor(spotlight, spotlightListenable) : null,
                        client: resolveClient(spotlight),
                        hideSpoilers: hideSpoilers ?? settings.read(SettingsService.hideSpoilers),
                        contentTop: spotlightTop,
                        contentBottom: spotlightBottom,
                        contentLeft: heroContentLeft,
                        targetWidthPx: (size.width * MediaQuery.devicePixelRatioOf(context)).ceil(),
                      );
                    },
                  ),
                  builder: (context, animatedBleed, child) =>
                      Positioned(top: 0, bottom: 0, left: -animatedBleed, width: fullBleedWidth, child: child!),
                );
              },
            ),
            foreground,
          ],
        ),
      ),
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => _handlePreviewKey(context, event),
      child: material,
    );
  }

  /// Play/Pause while a trailer previews opens it full-screen with sound.
  static KeyEventResult _handlePreviewKey(BuildContext context, KeyEvent event) {
    final key = event.logicalKey;
    final isPlayKey = key == LogicalKeyboardKey.mediaPlayPause || key == LogicalKeyboardKey.mediaPlay;
    if (!isPlayKey || !TrailerPreviewService.instance.isShowing) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      unawaited(() async {
        final trailer = await TrailerPreviewService.instance.takeTrailerForPlayback();
        if (trailer == null || !context.mounted) return;
        await navigateToVideoPlayer(context, metadata: trailer, resolveWatchState: false);
      }());
    }
    return KeyEventResult.handled;
  }
}

class _CatalogSpotlightBackground extends StatefulWidget {
  const _CatalogSpotlightBackground({
    required this.item,
    required this.client,
    required this.hideSpoilers,
    required this.contentTop,
    required this.contentBottom,
    required this.contentLeft,
    required this.targetWidthPx,
    this.action,
  });

  final MediaItem? item;
  final (String, IconData?)? action;
  final MediaServerClient? client;
  final bool hideSpoilers;
  final double contentTop;
  final double contentBottom;
  final double contentLeft;
  final int targetWidthPx;

  @override
  State<_CatalogSpotlightBackground> createState() => _CatalogSpotlightBackgroundState();
}

class _CatalogSpotlightBackgroundState extends State<_CatalogSpotlightBackground> {
  CatalogItem? _catalogItem;
  MediaItem? _renderItem;
  Color? _accentColor;

  bool _previewActive = false;

  @override
  void initState() {
    super.initState();
    _rehydrateCatalogItem();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Previews run only while this hero is on screen: the current route and,
    // in the main screen's tab stack, the visible tab.
    final active = TickerMode.valuesOf(context).enabled && (ModalRoute.of(context)?.isCurrent ?? true);
    if (active == _previewActive) return;
    _previewActive = active;
    if (active) {
      _focusPreview();
    } else {
      _stopOwnPreview();
    }
  }

  @override
  void didUpdateWidget(_CatalogSpotlightBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.item, oldWidget.item)) {
      _rehydrateCatalogItem();
      _focusPreview();
    } else if (widget.targetWidthPx != oldWidget.targetWidthPx) {
      _projectArtwork();
    }
  }

  @override
  void dispose() {
    _stopOwnPreview();
    super.dispose();
  }

  /// Preview calls notify listeners, so they run after the frame that
  /// triggered them (they are reached from build-phase callbacks).
  void _focusPreview() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyPreviewFocus();
    });
  }

  /// The hero that last drove the preview; only it may stop it.
  static Object? _previewOwner;

  void _applyPreviewFocus() {
    if (!_previewActive) return;
    _previewOwner = this;
    final item = widget.item;
    // Catalog (Discover) entries have no server extras to preview.
    final previewable = item != null && item.catalogItem == null ? item : null;
    final musicPlaying = Provider.of<MusicPlaybackService?>(context, listen: false)?.currentTrack != null;
    TrailerPreviewService.instance.focus(previewable, widget.client, otherAudioActive: musicPlaying);
  }

  void _stopOwnPreview() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!identical(_previewOwner, this)) return;
      _previewOwner = null;
      unawaited(TrailerPreviewService.instance.stop());
    });
  }

  void _rehydrateCatalogItem() {
    _catalogItem = widget.item?.catalogItem;
    _projectArtwork();
  }

  void _projectArtwork() {
    final item = widget.item;
    final catalogItem = _catalogItem;
    if (item == null || catalogItem == null) {
      _renderItem = item;
      _accentColor = null;
      return;
    }

    final bannerUrl = catalogItem.bannerUrl;
    final backdrop = bannerUrl != null && bannerUrl.isNotEmpty
        ? bannerUrl
        : catalogItem.backdropFor(widget.targetWidthPx);
    final logoUrl = catalogItem.logoUrl;
    _renderItem = item.copyWith(
      artPath: backdrop ?? item.artPath,
      backdropPaths: backdrop == null ? item.backdropPaths : [backdrop],
      clearLogoPath: logoUrl != null && logoUrl.isNotEmpty ? logoUrl : null,
    );
    _accentColor = _parseAccentColor(catalogItem.accentColor);
  }

  Color? _parseAccentColor(String? value) {
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(value ?? '');
    final hex = match?.group(1);
    if (hex == null) return null;
    return Color(0xff000000 | int.parse(hex, radix: 16));
  }

  Widget? _buildNextEpisodeMetadata(BuildContext context) {
    final nextEpisode = _catalogItem?.nextEpisode;
    if (nextEpisode == null) return null;
    final duration = formatDurationTextual(nextEpisode.timeUntil(DateTime.now()).inMilliseconds);
    final episode = nextEpisode.episode;
    final label = episode == null
        ? t.explore.badge.nextAiringIn(duration: duration)
        : t.explore.badge.nextEpisodeIn(episode: episode, duration: duration);
    final scale = TvLayoutConstants.scaleOf(context);
    return Text(
      label,
      maxLines: 1,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _accentColor;
    final background = TvSpotlightBackground(
      item: _renderItem,
      client: widget.client,
      hideSpoilers: widget.hideSpoilers,
      contentTop: widget.contentTop,
      contentBottom: widget.contentBottom,
      contentLeft: widget.contentLeft,
      compact: true,
      metadataTrailing: _buildNextEpisodeMetadata(context),
      actionLabel: widget.action?.$1,
      actionIcon: widget.action?.$2,
    );
    if (accentColor == null) return background;
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: Color.alphaBlend(accentColor.withValues(alpha: 0.18), theme.scaffoldBackgroundColor),
      ),
      child: background,
    );
  }
}

/// Pins a toolbar to the top of the viewport across the full bleed width,
/// sliding with the sidebar so it stays put while the content box translates.
///
/// Excluded from default focus traversal so that initial/tab-switch focus
/// lands on content (hero/rails) rather than the toolbar; its buttons stay
/// reachable via explicit UP from the content. Reads the offset aspect from
/// its own element, so a sidebar flip rebuilds only this overlay.
class TvToolbarOverlay extends StatelessWidget {
  const TvToolbarOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fullBleedWidth = MainScreenFocusScope.fullBleedWidthOf(context);
    return SideNavigationBleedBuilder(
      targetBleed: MainScreenFocusScope.sideNavigationBleedOf(context),
      // Authored in reference units like the rest of the TV chrome.
      child: ExcludeFocusTraversal(child: TvReferenceScale(child: child)),
      builder: (context, animatedBleed, child) =>
          Positioned(top: 0, left: -animatedBleed, width: fullBleedWidth, child: child!),
    );
  }
}
