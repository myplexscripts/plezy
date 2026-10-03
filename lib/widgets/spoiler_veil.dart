import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../media/media_item.dart';
import '../theme/plezzant/plezzant_typography.dart';
import '../utils/formatters.dart';
import 'app_icon.dart';

/// Hides spoiler artwork (an unwatched episode's still) without hiding which
/// episode it is: the image is blurred and darkened, and a label with the
/// episode number sits on top, so a row of blurred tiles stays navigable even
/// where cards show no captions.
class SpoilerVeil extends StatelessWidget {
  const SpoilerVeil({super.key, required this.child, this.label});

  final Widget child;

  /// What the tile is, e.g. "S2 E5". Null shows the hidden icon alone.
  final String? label;

  /// "S2 E5" (or "E5") for an episode, else its title.
  static String? labelFor(MediaItem item) =>
      formatSeasonEpisodeLabel(item.parentIndex, item.index) ?? item.displayTitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ClipRect(
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: child),
        ),
        Positioned.fill(
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Scale with the tile so the label reads on small rail cards
                // and large grid cells alike.
                final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 120.0;
                final fontSize = (h * 0.16).clamp(10.0, 28.0);
                return DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.28)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(LucideIcons.eyeOff, size: fontSize * 0.9, color: Colors.white70),
                        if (label != null) ...[
                          SizedBox(height: fontSize * 0.25),
                          Text(
                            label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: PlezzantTvType.family,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
