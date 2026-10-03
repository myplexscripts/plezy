
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app_icon.dart';
import '../../spoiler_veil.dart';

class MediaSelectorThumbnail extends StatelessWidget {
  final double width;
  final double height;
  final Widget? thumbnail;
  final bool isCurrent;
  final double radius;
  final Color borderColor;
  final Color fallbackBackgroundColor;
  final Color fallbackIconColor;
  final double fallbackIconSize;
  final IconData fallbackIcon;
  final bool blurThumbnail;

  /// Label shown over a blurred thumbnail (e.g. "S1 E3").
  final String? blurLabel;

  const MediaSelectorThumbnail({
    super.key,
    required this.width,
    required this.height,
    required this.thumbnail,
    required this.isCurrent,
    required this.borderColor,
    this.radius = 4,
    this.fallbackBackgroundColor = Colors.white10,
    this.fallbackIconColor = Colors.white38,
    this.fallbackIconSize = 28,
    this.fallbackIcon = LucideIcons.film,
    this.blurThumbnail = false,
    this.blurLabel,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.all(Radius.circular(radius));
    final child = thumbnail != null
        ? _maybeBlurThumbnail(thumbnail!)
        : Container(
            color: fallbackBackgroundColor,
            child: Center(
              child: AppIcon(fallbackIcon, fill: 1, color: fallbackIconColor, size: fallbackIconSize),
            ),
          );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          ClipRRect(borderRadius: borderRadius, child: child),
          if (isCurrent)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.fromBorderSide(BorderSide(color: borderColor, width: 2)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _maybeBlurThumbnail(Widget child) {
    if (!blurThumbnail) return child;
    return SpoilerVeil(label: blurLabel, child: child);
  }
}
