import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../services/device_performance.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import '../utils/tone_mapped_logo_image.dart';
import '../theme/plezzant/ultra_blur.dart';
import '../theme/plezzant/plezzant_tokens.dart';
import 'cycling_media_backdrop.dart';
import 'trailer_chrome_fade.dart';
import 'fitting_title_text.dart';
import 'app_icon.dart';
import '../theme/plezzant/plezzant_typography.dart';
import 'fitted_metadata_line.dart';
import 'media_ambience.dart';
import 'media_rating_badge.dart';
import 'optimized_media_image.dart' show ClearLogoImage, blurArtwork;
import 'rasterized_gradient.dart';
import '../services/trailer_preview_service.dart';
import '../mpv/video.dart';
import '../theme/plezzant/control_tint.dart';

class TvSpotlightBackground extends StatelessWidget {
  final MediaItem? item;
  final MediaServerClient? client;
  final bool hideSpoilers;
  final double contentBottom;
  final double? contentTop;
  final double? contentLeft;
  final bool compact;
  final bool showInfo;
  final String? Function(String? artworkPath)? localArtworkPathResolver;
  final bool allowNetwork;

  /// Optional caller-owned fact appended to the existing metadata line.
  final Widget? metadataTrailing;

  /// Apple TV style call to action under the synopsis: names what OK does on
  /// the focused card. Purely a label; the card owns the focus and the press.
  final String? actionLabel;
  final IconData? actionIcon;

  const TvSpotlightBackground({
    super.key,
    required this.item,
    required this.client,
    this.hideSpoilers = false,
    this.contentBottom = 360,
    this.contentTop,
    this.contentLeft,
    this.compact = false,
    this.showInfo = true,
    this.localArtworkPathResolver,
    this.allowNetwork = true,
    this.metadataTrailing,
    this.actionLabel,
    this.actionIcon,
  });

  double _scale(BuildContext context) => TvLayoutConstants.scaleOf(context);

  @override
  Widget build(BuildContext context) {
    final media = item;
    // The gradients never differ between spotlight items, so only the artwork
    // cross-fades by image paint alpha. Keeping the gradients outside the
    // rotating layer avoids full-screen saveLayers on low-end TVs.
    final size = MediaQuery.sizeOf(context);
    // Palette ambience (focus tints) and the UltraBlur both follow the item
    // the viewer settles on.
    if (allowNetwork) {
      requestAmbienceForItem(media, client);
      UltraBlurAmbience.instance.request(media, client);
    }
    final fallbackPaths = media == null
        ? const <String>[]
        : <String>[...media.heroArtCandidates(containerAspectRatio: 16 / 9), ?media.thumbPath];
    // Plex layout: the backdrop sits in the top-right corner and dissolves
    // into the UltraBlur, so the copy reads on calm colour, never on art.
    final artWidth = size.width * _artWidthFraction;
    final artHeight = math.min(artWidth * 9 / 16, size.height * 0.84);
    final backdrop = CyclingMediaBackdrop(
      mediaKey: media?.globalKey,
      imagePaths: media?.heroRotationPaths(containerAspectRatio: 16 / 9) ?? const [],
      fallbackImagePaths: fallbackPaths,
      client: client,
      localArtworkPathResolver: localArtworkPathResolver == null ? null : (path) => localArtworkPathResolver!(path),
      allowNetwork: allowNetwork,
      width: artWidth,
      height: artHeight,
      fallbackColor: Colors.transparent,
    );
    final background = RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [const UltraBlurBackground(), _buildCornerBackdrop(Size(artWidth, artHeight), blurArtwork(backdrop))],
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        // A previewing trailer replaces the background: its surface sits under
        // the scrims, and the UltraBlur and art fade away once a frame is up.
        ListenableBuilder(
          listenable: TrailerPreviewService.instance,
          builder: (context, child) {
            final preview = TrailerPreviewService.instance;
            final player = preview.player;
            // The surface mounts once playback is live, so the position it
            // reports reaches an initialized native player.
            final showing = preview.isShowingFor(media);
            final previewing = showing && player != null;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (previewing) Video(player: player, backgroundColor: Colors.transparent),
                AnimatedOpacity(
                  opacity: showing ? 0 : 1,
                  duration: DevicePerformance.reducedDuration(const Duration(milliseconds: 900)),
                  curve: PlezzantMotion.standard,
                  child: child,
                ),
              ],
            );
          },
          child: background,
        ),
        // Soft readability behind the copy and a light top edge for the
        // floating chrome; the UltraBlur itself stays clean.
        TrailerChromeFade(
          child: RasterizedGradient(
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.26), Colors.black.withValues(alpha: 0.08), Colors.transparent],
              stops: const [0.0, 0.38, 0.6],
            ),
          ),
        ),
        TrailerChromeFade(
          child: RasterizedGradient(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.16),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.22),
              ],
              stops: const [0.0, 0.22, 0.62, 1.0],
            ),
          ),
        ),
        if (media != null && showInfo)
          AnimatedPositioned(
            duration: DevicePerformance.reducedDuration(PlezzantMotion.navigation),
            curve: PlezzantMotion.standard,
            left: contentLeft ?? TvLayoutConstants.horizontalInset,
            // tvOS keeps hero copy to a readable measure.
            right: _heroRightInset(context, contentLeft ?? TvLayoutConstants.horizontalInset),
            top: contentTop,
            bottom: contentBottom,
            // The info block still cross-fades via AnimatedSwitcher, but its
            // saveLayers are bounded to the text region, not the screen.
            child: TrailerChromeFade(
              child: AnimatedSwitcher(
                duration: DevicePerformance.reducedDuration(PlezzantMotion.hero),
                reverseDuration: DevicePerformance.reducedDuration(PlezzantMotion.revealOut),
                switchInCurve: PlezzantMotion.standard,
                switchOutCurve: PlezzantMotion.exit,
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: PlezzantMotion.standard,
                    reverseCurve: PlezzantMotion.exit,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero).animate(curved),
                      child: child,
                    ),
                  );
                },
                // Expand instead of the default loose centered Stack so the
                // info keeps filling the region and bottom-left aligning.
                layoutBuilder: (currentChild, previousChildren) =>
                    Stack(fit: StackFit.expand, children: [...previousChildren, ?currentChild]),
                child: KeyedSubtree(
                  key: ValueKey(media.globalKey),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (!constraints.hasBoundedHeight || constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
                        return Align(alignment: .bottomLeft, child: _buildInfo(context, media));
                      }

                      return Align(
                        alignment: .bottomLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: .bottomLeft,
                          child: SizedBox(width: constraints.maxWidth, child: _buildInfo(context, media)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Width of the corner backdrop on the reference layout (Plex: ~3/4).
  static const double _artWidthFraction = 0.74;

  /// Corner spotlight: artwork pinned to the top-right corner, left and
  /// bottom edges feathered into the scaffold background so the info block
  /// sits on a calm surface instead of the image.
  Widget _buildCornerBackdrop(Size backdropSize, Widget backdrop) {
    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: backdropSize.width,
        height: backdropSize.height,
        child: ShaderMask(
          shaderCallback: (rect) =>
              const LinearGradient(colors: [Colors.transparent, Colors.white], stops: [0.0, 0.42]).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.5, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: backdrop,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, MediaItem media) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    final shouldHideSpoiler = hideSpoilers && media.shouldHideSpoiler;
    final summary = shouldHideSpoiler ? null : media.summary;
    final title = media.grandparentTitle ?? media.displayTitle;

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        _buildLogoOrTitle(context, media, title),
        SizedBox(height: _sectionGap(scale)),
        _buildMetadataLine(context, media),
        if (summary != null && summary.isNotEmpty) ...[
          SizedBox(height: _sectionGap(scale)),
          Text(
            summary,
            maxLines: compact ? 3 : 4,
            overflow: .ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.78),
              fontSize: _summaryFontSize(scale),
              height: compact ? 1.34 : 1.45,
            ),
          ),
        ] else if (shouldHideSpoiler && media.isEpisode) ...[
          SizedBox(height: _sectionGap(scale)),
          Text(
            media.title ?? '',
            maxLines: 2,
            overflow: .ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: _summaryFontSize(scale),
              height: compact ? 1.34 : 1.45,
            ),
          ),
        ],
        if (actionLabel != null) ...[
          SizedBox(height: _sectionGap(scale) * 1.4),
          ListenableBuilder(
            listenable: TrailerPreviewService.instance,
            builder: (context, _) {
              final previewing = TrailerPreviewService.instance.isShowingFor(media);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionPill(label: actionLabel!, icon: actionIcon, scale: scale),
                  // While its trailer previews: what the remote's Play/Pause
                  // key does.
                  AnimatedSwitcher(
                    duration: DevicePerformance.reducedDuration(PlezzantMotion.reveal),
                    child: previewing
                        ? Padding(
                            padding: EdgeInsets.only(left: 16 * scale),
                            child: _PreviewHint(scale: scale),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLogoOrTitle(BuildContext context, MediaItem media, String title) {
    final theme = Theme.of(context);
    // The spotlight scrim washes artwork toward the scaffold background, so
    // light themes recolor light-toned logos to stay visible.
    final logoToneTarget = logoToneTargetFor(
      surface: theme.scaffoldBackgroundColor,
      foreground: theme.colorScheme.onSurface,
    );
    final scale = _scale(context);
    final logoPath = media.clearLogoPath;
    final logoWidth = _logoWidth(scale);
    final logoHeight = _logoHeight(scale);
    if (logoPath == null || logoPath.isEmpty) {
      return SizedBox(width: logoWidth, height: logoHeight, child: _buildTitle(context, title));
    }
    final pixelRatio = MediaImageHelper.artworkPixelRatio(context, imageType: ImageType.heroLogo);
    final (logoMemWidth, logoMemHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: (logoWidth * pixelRatio).round(),
      displayHeight: (logoHeight * pixelRatio).round(),
      imageType: ImageType.heroLogo,
    );

    final localLogoPath = localArtworkPathResolver?.call(logoPath);
    if (localLogoPath != null && File(localLogoPath).existsSync()) {
      final bounded = MediaImageHelper.boundedDecode(
        FileImage(File(localLogoPath)),
        memWidth: logoMemWidth,
        memHeight: logoMemHeight,
      );
      return SizedBox(
        width: logoWidth,
        height: logoHeight,
        child: blurArtwork(
          Image(
            image: logoToneTarget == null
                ? bounded
                : ToneMappedLogoImage(bounded, target: logoToneTarget, remapMixed: false),
            fit: BoxFit.contain,
            filterQuality: MediaImageHelper.artworkFilterQuality(context, ImageType.heroLogo),
            alignment: .bottomLeft,
            errorBuilder: (context, error, stackTrace) => _buildTitle(context, title),
          ),
          sigma: 10,
          clip: false,
        ),
      );
    }

    return ClearLogoImage(
      client: client,
      logoPath: logoPath,
      width: logoWidth,
      height: logoHeight,
      fadeInDuration: DevicePerformance.reducedDuration(const Duration(milliseconds: 200)),
      logoToneTarget: logoToneTarget,
      // Wide logos sit on the metadata line, not mid-box.
      alignment: Alignment.bottomLeft,
      fallbackBuilder: (context) => _buildTitle(context, title),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    return FittingTitleText(
      title,
      alignment: Alignment.bottomLeft,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: _titleFontSize(scale),
        fontWeight: .w800,
        shadows: [Shadow(color: colorScheme.surface.withValues(alpha: 0.8), blurRadius: 12)],
      ),
    );
  }

  Widget _buildMetadataLine(BuildContext context, MediaItem media) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    final episodeLabel = formatSeasonEpisodeLabel(media.parentIndex, media.index);
    final textStyle = TextStyle(
      // Painted by its own TextPainter, so it cannot inherit the theme font.
      fontFamily: PlezzantType.family,
      color: colorScheme.onSurface,
      fontSize: _metadataFontSize(scale),
      fontWeight: .w600,
      letterSpacing: 0.1,
    );

    final parts = <MetadataLinePart>[];
    if (media.isEpisode && episodeLabel != null) parts.add(MetadataLineText(episodeLabel, dropPriority: 0));
    // Apple TV style: lead with the genre when the listing carries one.
    final genre = media.genres?.firstOrNull;
    if (genre != null && genre.isNotEmpty && !media.isEpisode) {
      parts.add(MetadataLineText(genre, dropPriority: 3));
    } else if (media.isMovie) {
      parts.add(MetadataLineText(t.discover.movie, dropPriority: 3));
    } else if (media.isShow) {
      parts.add(MetadataLineText(t.discover.tvShow, dropPriority: 3));
    }
    // Hub listings carry the scalar rating pair, so the dashboard spotlight
    // shows every score the shelf request already returned — no per-item
    // hydration to lengthen it.
    final ratings = mediaRatingsFor(media);
    if (ratings.isNotEmpty) parts.add(MetadataLineRatings(ratings, dropPriority: 4));
    if (media.durationMs != null) {
      parts.add(MetadataLineText(formatDurationTextual(media.durationMs!), dropPriority: 1));
    }
    if (media.isEpisode && media.originallyAvailableAt != null) {
      parts.add(MetadataLineText(formatFullDate(media.originallyAvailableAt!), dropPriority: 0));
    } else if (media.year != null) {
      parts.add(MetadataLineText(media.year.toString(), dropPriority: 0));
    }

    final line = parts.isEmpty
        ? null
        : FittedMetadataLine(
            textStyle: textStyle,
            parts: parts,
            ratingIconSize: textStyle.fontSize,
            ratingSpacing: 4 * scale,
            ratingEntrySpacing: 12 * scale,
          );
    // The content rating sits in an outlined badge after the line.
    final rating = media.contentRating;
    final badge = rating == null || rating.isEmpty
        ? null
        : Container(
            margin: EdgeInsets.only(left: 10 * scale),
            padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 1 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.7), width: 1.2),
              borderRadius: BorderRadius.circular(4 * scale),
            ),
            child: Text(
              formatContentRating(rating),
              maxLines: 1,
              style: textStyle.copyWith(fontSize: textStyle.fontSize! * 0.78, height: 1.2),
            ),
          );
    final trailing = metadataTrailing;
    if (trailing == null && badge == null) return line ?? const SizedBox.shrink();
    return Row(
      mainAxisSize: .min,
      children: [
        if (line != null) Flexible(child: line),
        ?badge,
        if (trailing != null) ...[
          // The trailing fact is caller-owned and always shown; the line fits
          // itself into whatever width the trailing widget leaves over.
          Text(FittedMetadataLine.separator, maxLines: 1, style: textStyle),
          trailing,
        ],
      ],
    );
  }

  double _heroRightInset(BuildContext context, double left) {
    final width = MediaQuery.sizeOf(context).width;
    final textWidth = PlezzantTv.heroTextWidth * _scale(context);
    return math.max(width * 0.3, width - left - textWidth);
  }

  double _sectionGap(double scale) => (compact ? 12 : 18) * scale;

  double _logoWidth(double scale) =>
      (compact ? TvLayoutConstants.compactHeroLogoWidth : TvLayoutConstants.heroLogoWidth) * scale;

  double _logoHeight(double scale) =>
      (compact ? TvLayoutConstants.compactHeroLogoHeight : TvLayoutConstants.heroLogoHeight) * scale;

  double _titleFontSize(double scale) => (compact ? 56 : 76) * scale;

  double _metadataFontSize(double scale) => (compact ? 21 : 23) * scale;

  double _summaryFontSize(double scale) => (compact ? 22 : 24) * scale;
}

/// Glass hint beside the action pill while a trailer previews: Play/Pause
/// watches it with sound.
class _PreviewHint extends StatelessWidget {
  const _PreviewHint({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return TintedControl(
      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 14 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(LucideIcons.squarePlay, size: 24 * scale, color: Colors.white),
          SizedBox(width: 10 * scale),
          Text(
            t.common.watchTrailer,
            maxLines: 1,
            style: PlezzantType.labelLarge.copyWith(
              color: Colors.white,
              fontSize: 21 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 12 * scale),
          AppIcon(LucideIcons.circlePlay, size: 20 * scale, color: Colors.white70),
        ],
      ),
    );
  }
}

/// The hero's "Play" / "Go to Show" label: what OK does on the focused card.
class _ActionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double scale;

  const _ActionPill({required this.label, required this.icon, required this.scale});

  @override
  Widget build(BuildContext context) {
    // Same glass as the detail page's resting action buttons, so Home and a
    // title's page share one button language (a big white slab blooms on TV
    // panels and washes its label out).
    return TintedControl(
      padding: EdgeInsets.symmetric(horizontal: 30 * scale, vertical: 14 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, fill: 1, size: 24 * scale, color: Colors.white),
            SizedBox(width: 10 * scale),
          ],
          Text(
            label,
            maxLines: 1,
            style: PlezzantType.labelLarge.copyWith(
              color: Colors.white,
              fontSize: 23 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
