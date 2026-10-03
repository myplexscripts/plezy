import 'package:flutter/material.dart';

import '../theme/plezzant/plezzant_tokens.dart';
import '../utils/desktop_window_padding.dart';
import '../utils/platform_detector.dart';
import 'app_bar_back_button.dart';
import 'tv_reference_scale.dart';

/// The back control every pushed detail page shows, positioned for a [Stack].
///
/// On a TV it is a small circular chip on the reference canvas in the section
/// pill's slot, so detail, collection, playlist and album pages all put "back"
/// in the same place at the same size. Elsewhere it is the circular button in
/// the top-left corner.
class PositionedDetailBackButton extends StatelessWidget {
  const PositionedDetailBackButton({super.key, required this.onPressed, this.focusNode});

  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final button = DesktopAppBarHelper.buildAdjustedLeading(
      AppBarBackButton(style: BackButtonStyle.circular, onPressed: onPressed, focusNode: focusNode),
      context: context,
    )!;
    if (!PlatformDetector.isTV()) return Positioned(top: 0, left: 0, child: button);
    final scale = PlezzantTv.scaleOf(context);
    return Positioned(
      top: (PlezzantTv.sectionPillTop - 12) * scale,
      left: (PlezzantTv.sectionPillLeft - 12) * scale,
      child: TvReferenceScale(child: button),
    );
  }
}
