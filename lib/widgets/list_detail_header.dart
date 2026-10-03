import 'package:flutter/material.dart';

import '../theme/mono_tokens.dart';
import '../theme/plezzant/plezzant_tokens.dart';
import '../theme/plezzant/plezzant_typography.dart';
import '../utils/platform_detector.dart';

/// The header shared by pages that list a container's items: collections,
/// playlists and photo albums.
///
/// Artwork on the left, then title, a muted metadata line, an optional
/// summary and the action bar, bottom-aligned with the artwork. On a TV it
/// sits on the safe frame under the back chip and uses the reference-canvas
/// type roles, so every list page reads like the movie and show pages.
/// [compact] (phones) stacks everything centred.
class ListDetailHeader extends StatelessWidget {
  const ListDetailHeader({
    super.key,
    this.artwork,
    required this.title,
    required this.meta,
    required this.actionBar,
    this.badge,
    this.summary,
    this.compact = false,
  });

  /// Builds the artwork at the given height; the builder picks the width
  /// from its own aspect ratio. Null for pages without artwork.
  final Widget Function(double height)? artwork;
  final String title;
  final String meta;

  /// Optional line under the title (e.g. the smart playlist badge).
  final Widget? badge;

  /// Optional summary, already styled; [summaryStyle] gives the matching style.
  final Widget? summary;
  final Widget actionBar;
  final bool compact;

  /// Title artwork height on the reference canvas.
  static const double tvArtworkHeight = 360;

  static TextStyle? titleStyle(BuildContext context) => PlatformDetector.isTV()
      ? PlezzantTvType.of(context, PlezzantTvType.hero)
      : Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);

  static TextStyle? metaStyle(BuildContext context) => PlatformDetector.isTV()
      ? PlezzantTvType.of(context, PlezzantTvType.metadata).copyWith(color: tokens(context).textMuted)
      : Theme.of(context).textTheme.bodyMedium?.copyWith(color: tokens(context).textMuted);

  static TextStyle? summaryStyle(BuildContext context) => PlatformDetector.isTV()
      ? PlezzantTvType.of(context, PlezzantTvType.body).copyWith(color: tokens(context).textMuted)
      : Theme.of(context).textTheme.bodyMedium?.copyWith(color: tokens(context).textMuted);

  /// Horizontal page inset: the safe frame on a TV.
  static double insetOf(BuildContext context) =>
      PlatformDetector.isTV() ? PlezzantTv.safeX * PlezzantTv.scaleOf(context) : 16;

  @override
  Widget build(BuildContext context) {
    final isTv = PlatformDetector.isTV();
    final scale = PlezzantTv.scaleOf(context);
    final inset = insetOf(context);
    final top = MediaQuery.paddingOf(context).top + (isTv ? PlezzantTv.sectionPillBand * scale : kToolbarHeight + 8);
    final bottom = isTv ? 24 * scale : 12.0;
    final gap = isTv ? 40 * scale : 24.0;

    Widget info({required bool centered}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle(context),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (badge != null) ...[SizedBox(height: isTv ? 8 * scale : 4), badge!],
        if (meta.isNotEmpty) ...[
          SizedBox(height: isTv ? 8 * scale : 4),
          Text(meta, style: metaStyle(context), textAlign: centered ? TextAlign.center : TextAlign.start),
        ],
        if (summary != null) ...[
          SizedBox(height: isTv ? 16 * scale : 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTv ? PlezzantTv.heroTextWidth * scale : 720),
            child: summary,
          ),
        ],
        SizedBox(height: isTv ? 24 * scale : 16),
        actionBar,
      ],
    );

    if (compact) {
      return Padding(
        padding: EdgeInsets.fromLTRB(inset, top, inset, bottom),
        child: Column(children: [?artwork?.call(240), const SizedBox(height: 16), info(centered: true)]),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, top, inset, bottom),
      child: artwork == null
          ? info(centered: false)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                artwork!(isTv ? tvArtworkHeight * scale : 240),
                SizedBox(width: gap),
                Expanded(child: info(centered: false)),
              ],
            ),
    );
  }
}
