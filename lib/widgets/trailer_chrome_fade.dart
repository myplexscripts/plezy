import 'package:flutter/widgets.dart';

import '../services/trailer_preview_service.dart';

/// Fades [child] out while a Home trailer preview has the screen to itself
/// (see [TrailerPreviewService.uiHidden]); any remote press brings it back.
/// Focus and layout are untouched, so the next press lands where it would
/// have.
class TrailerChromeFade extends StatelessWidget {
  const TrailerChromeFade({super.key, required this.child});

  final Widget child;

  static const Duration duration = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TrailerPreviewService.instance,
      builder: (context, child) => AnimatedOpacity(
        opacity: TrailerPreviewService.instance.uiHidden ? 0 : 1,
        duration: duration,
        curve: Curves.easeInOut,
        child: child,
      ),
      child: child,
    );
  }
}
