import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../focus/focusable_action_bar.dart';
import '../../i18n/strings.g.dart';
import '../../media/library_query.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../mixins/grid_focus_node_mixin.dart';
import '../../mixins/paginated_item_loader.dart';
import '../../mixins/standard_paginated_view.dart';
import '../../theme/mono_tokens.dart';
import '../../theme/plezzant/plezzant_tokens.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/error_message_utils.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/media_server_http_client.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_bar_back_button.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/rasterized_gradient.dart';
import '../../widgets/tv_reference_scale.dart';
import '../base_media_list_detail_screen.dart';
import '../focusable_detail_screen_mixin.dart';
import 'photo_sequence_scope.dart';
import 'photo_viewer_screen.dart';

/// A photo album: cover, title and count over a grid of its photos, laid out
/// like the collection page, with Slideshow and Shuffle in the action row.
class PhotoAlbumScreen extends StatefulWidget {
  final MediaItem album;

  const PhotoAlbumScreen({super.key, required this.album});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends BaseMediaListDetailScreen<PhotoAlbumScreen>
    with
        GridFocusNodeMixin<PhotoAlbumScreen>,
        FocusableDetailScreenMixin<PhotoAlbumScreen>,
        PaginatedItemLoader<MediaItem, PhotoAlbumScreen>,
        PaginatedItemUpdatable<PhotoAlbumScreen>,
        StandardPaginatedView<MediaItem, PhotoAlbumScreen> {
  static const int _pageSize = 200;

  @override
  MediaItem get mediaItem => widget.album;

  @override
  String get title => widget.album.displayTitle;

  @override
  String get emptyMessage => t.photos.noPhotos;

  @override
  IconData? get emptyIcon => LucideIcons.images;

  @override
  bool get hasItems => totalSize > 0;

  /// Loaded entries in grid order.
  List<MediaItem> get _orderedItems => [for (var i = 0; i < totalSize; i++) ?loadedItems[i]];

  @override
  void dispose() {
    disposePagination();
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    return mediaClient.fetchChildrenPage(widget.album.id, start: start, size: size, abort: abort);
  }

  @override
  Future<void> loadItems() {
    return loadStandardPaginatedItems(
      pageSize: _pageSize,
      errorMessageFor: (error, stackTrace) => localizedLoadErrorMessage(error, stackTrace, context: t.photos.photos),
      onLoaded: (_, _) => autoFocusFirstItemAfterLoad(),
    );
  }

  Future<void> _slideshow({required bool shuffle}) async {
    final photos = _orderedItems.where((i) => i.isPhoto).toList();
    if (photos.isEmpty) return;
    if (shuffle) photos.shuffle();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerScreen(items: photos, initialIndex: 0, client: mediaClient, startSlideshow: true),
      ),
    );
  }

  @override
  List<FocusableAction> getAppBarActions() => [
    if (hasItems) ...[
      FocusableAction(icon: LucideIcons.play, tooltip: t.photos.slideshow, onPressed: () => _slideshow(shuffle: false)),
      FocusableAction(
        icon: LucideIcons.shuffle,
        tooltip: t.photos.shuffleSlideshow,
        onPressed: () => _slideshow(shuffle: true),
      ),
    ],
  ];

  String? get _coverPath => widget.album.thumbPath ?? _orderedItems.where((i) => i.isPhoto).firstOrNull?.thumbPath;

  Widget _buildHeader(BuildContext context, {required bool isTv}) {
    final theme = Theme.of(context);
    final scale = PlezzantTv.scaleOf(context);
    final inset = isTv ? PlezzantTv.safeX * scale : 16.0;
    final topInset = MediaQuery.paddingOf(context).top + (isTv ? PlezzantTv.sectionPillBand * scale : kToolbarHeight);
    final coverHeight = isTv ? 220 * scale : 160.0;
    final count = totalSize > 0 ? totalSize : (widget.album.leafCount ?? widget.album.childCount ?? 0);
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, topInset, inset, isTv ? 24 * scale : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(PlezzantRadius.card),
            child: OptimizedMediaImage(
              client: mediaClient,
              imagePath: _coverPath,
              imageType: ImageType.thumb,
              width: coverHeight * 16 / 9,
              height: coverHeight,
              fallbackIcon: LucideIcons.images,
            ),
          ),
          SizedBox(width: isTv ? 32 * scale : 24),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.album.displayTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  t.photos.photoCount(n: count),
                  style: theme.textTheme.bodyMedium?.copyWith(color: tokens(context).textMuted),
                ),
                const SizedBox(height: 16),
                FocusableActionBar(
                  key: actionBarKey,
                  spacing: 4,
                  actions: getAppBarActions(),
                  onNavigateDown: navigateToGrid,
                  onBack: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The album cover, blurred into a colour wash behind the header like the
  /// collection page's poster fallback.
  Widget _buildBackdropLayer(BuildContext context, {required Size size, required double height}) {
    final path = _coverPath;
    if (path == null) return const SizedBox.shrink();
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final offset = scrollController.hasClients ? scrollController.offset : 0.0;
            return Transform.translate(offset: Offset(0, -offset), child: child);
          },
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40, tileMode: TileMode.clamp),
                    child: OptimizedMediaImage(
                      client: mediaClient,
                      imagePath: path,
                      imageType: ImageType.art,
                      width: size.width,
                      height: height,
                    ),
                  ),
                ),
                RasterizedGradient(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg.withValues(alpha: 0.45), bg.withValues(alpha: 0.8), bg],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTv = PlatformDetector.isTV();
    final scale = PlezzantTv.scaleOf(context);
    final inset = isTv ? PlezzantTv.safeX * scale : 16.0;
    return PhotoSequenceScope(
      items: () => _orderedItems,
      child: buildDetailScaffold(
        behind: [_buildBackdropLayer(context, size: size, height: size.height * 0.6)],
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isTv: isTv)),
          ...buildStateSlivers(),
          if (hasItems)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isTv ? inset - 8 * scale : 8),
              sliver: buildSparseFocusableGrid(
                totalItems: totalSize,
                itemAt: (index) => loadedItems[index],
                onRefresh: updateItem,
                onSkeletonVisible: (index) => ensureIndexLoaded(index, pageSize: _pageSize),
                onListRefresh: loadItems,
                shape: CardShape.wide,
              ),
            ),
        ],
        above: [
          Positioned(
            top: isTv ? (PlezzantTv.sectionPillTop - 12) * scale : 0,
            left: isTv ? (PlezzantTv.sectionPillLeft - 12) * scale : 0,
            child: TvReferenceScale(
              child: DesktopAppBarHelper.buildAdjustedLeading(
                AppBarBackButton(style: BackButtonStyle.circular, onPressed: () => Navigator.pop(context)),
                context: context,
              )!,
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether [item] opens in the photo viewer (photos, and videos kept in a
/// photo library).
bool isPhotoViewerItem(MediaItem item) => item.isPhoto || item.kind == MediaKind.clip;
