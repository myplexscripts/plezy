import 'dart:io';

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../services/device_performance.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import '../services/settings_service.dart';
import '../utils/tone_mapped_logo_image.dart';
import 'cycling_media_backdrop.dart';
import 'fitting_title_text.dart';
import 'fitted_metadata_line.dart';
import 'settings_builder.dart';
import 'media_rating_badge.dart';
import 'optimized_media_image.dart' show ClearLogoImage, blurArtwork;
import 'rasterized_gradient.dart';

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

  final Widget? metadataTrailing;

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
  });

  double _scale(BuildContext context) => TvLayoutConstants.scaleOf(context);

  @override
  Widget build(BuildContext context) {
    final media = item;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final size = MediaQuery.sizeOf(context);
    final containerAspect = size.width / size.height;
    final fallbackPaths = media == null
        ? const <String>[]
        : <String>[...media.heroArtCandidates(containerAspectRatio: containerAspect), ?media.thumbPath];

    return SettingValueBuilder<bool>(
      pref: SettingsService.tvCornerSpotlightBackdrop,
      builder: (context, cornerBackdrop, _) {
        final backdropSize = cornerBackdrop ? Size(size.width * 0.72, size.height * 0.76) : size;
        final backdrop = CyclingMediaBackdrop(
          mediaKey: media?.globalKey,
          imagePaths: media?.heroRotationPaths(containerAspectRatio: containerAspect) ?? const [],
          fallbackImagePaths: fallbackPaths,
          client: client,
          localArtworkPathResolver: localArtworkPathResolver == null ? null : (path) => localArtworkPathResolver!(path),
          allowNetwork: allowNetwork,
          width: size.width,
          height: size.height,
          fallbackColor: media == null ? bgColor : Theme.of(context).colorScheme.surfaceContainerHighest,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: cornerBackdrop ? _buildCornerBackdrop(backdropSize, backdrop) : blurArtwork(backdrop),
            ),
            _buildHorizontalScrim(bgColor),
            RasterizedGradient(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.26), Colors.transparent, bgColor.withValues(alpha: 0.94)],
                stops: const [0.0, 0.44, 1.0],
              ),
            ),
            if (media != null && showInfo)
              Positioned(
                left: contentLeft ?? TvLayoutConstants.horizontalInset,
                right: MediaQuery.sizeOf(context).width * 0.42,
                top: contentTop,
                bottom: contentBottom,
                child: AnimatedSwitcher(
                  duration: DevicePerformance.reducedDuration(const Duration(milliseconds: 320)),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  layoutBuilder: (currentChild, previousChildren) =>
                      Stack(fit: StackFit.expand, children: [...previousChildren, ?currentChild]),
                  child: KeyedSubtree(
                    key: ValueKey(media.globalKey),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (!constraints.hasBoundedHeight || constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
                          return Align(alignment: Alignment.bottomLeft, child: _buildInfo(context, media));
                        }

                        return Align(
                          alignment: Alignment.bottomLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(width: constraints.maxWidth, child: _buildInfo(context, media)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCornerBackdrop(Size backdropSize, Widget backdrop) {
    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: backdropSize.width,
        height: backdropSize.height,
        child: ShaderMask(
          shaderCallback: (rect) =>
              const LinearGradient(colors: [Colors.transparent, Colors.white], stops: [0.0, 0.32]).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.60, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: backdrop,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalScrim(Color bgColor) {
    return RasterizedGradient(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [bgColor.withValues(alpha: 0.92), bgColor.withValues(alpha: 0.48), Colors.transparent],
        stops: const [0.0, 0.43, 0.82],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogoOrTitle(context, media, title),
        SizedBox(height: _sectionGap(scale)),
        _buildMetadataLine(context, media),
        if (summary != null && summary.isNotEmpty) ...[
          SizedBox(height: _sectionGap(scale)),
          Text(
            summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.86),
              fontSize: _summaryFontSize(scale),
              fontWeight: FontWeight.w400,
              height: 1.42,
              letterSpacing: -0.2,
            ),
          ),
        ] else if (shouldHideSpoiler && media.isEpisode) ...[
          SizedBox(height: _sectionGap(scale)),
          Text(
            media.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.82),
              fontSize: _summaryFontSize(scale),
              height: 1.42,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoOrTitle(BuildContext context, MediaItem media, String title) {
    final theme = Theme.of(context);
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
            alignment: Alignment.centerLeft,
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
      fadeInDuration: DevicePerformance.reducedDuration(const Duration(milliseconds: 220)),
      logoToneTarget: logoToneTarget,
      fallbackBuilder: (context) => _buildTitle(context, title),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    return FittingTitleText(
      title,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: _titleFontSize(scale),
        fontWeight: FontWeight.w800,
        letterSpacing: -1.35,
        height: 1.02,
        shadows: [Shadow(color: colorScheme.surface.withValues(alpha: 0.62), blurRadius: 18)],
      ),
    );
  }

  Widget _buildMetadataLine(BuildContext context, MediaItem media) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    final episodeLabel = formatSeasonEpisodeLabel(media.parentIndex, media.index);
    final textStyle = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.92),
      fontFamily: 'Inter',
      fontSize: _metadataFontSize(scale),
      fontWeight: FontWeight.w600,
      letterSpacing: -0.12,
    );

    final parts = <MetadataLinePart>[];
    if (media.isEpisode && episodeLabel != null) parts.add(MetadataLineText(episodeLabel, dropPriority: 0));
    if (media.isMovie) {
      parts.add(MetadataLineText(t.discover.movie, dropPriority: 3));
    } else if (media.isShow) {
      parts.add(MetadataLineText(t.discover.tvShow, dropPriority: 3));
    }
    final ratings = mediaRatingsFor(media);
    if (ratings.isNotEmpty) parts.add(MetadataLineRatings(ratings, dropPriority: 4));
    if (media.contentRating != null) {
      parts.add(MetadataLineText(formatContentRating(media.contentRating!), dropPriority: 2));
    }
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
    final trailing = metadataTrailing;
    if (trailing == null) return line ?? const SizedBox.shrink();
    if (line == null) return trailing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: line),
        Text(FittedMetadataLine.separator, maxLines: 1, style: textStyle),
        trailing,
      ],
    );
  }

  double _sectionGap(double scale) => (compact ? 12 : 18) * scale;

  double _logoWidth(double scale) =>
      (compact ? TvLayoutConstants.compactHeroLogoWidth : TvLayoutConstants.heroLogoWidth) * scale * 1.10;

  double _logoHeight(double scale) =>
      (compact ? TvLayoutConstants.compactHeroLogoHeight : TvLayoutConstants.heroLogoHeight) * scale * 1.10;

  double _titleFontSize(double scale) => (compact ? 58 : 70) * scale;

  double _metadataFontSize(double scale) => (compact ? 16 : 18) * scale;

  double _summaryFontSize(double scale) => (compact ? 19 : 22) * scale;
}
