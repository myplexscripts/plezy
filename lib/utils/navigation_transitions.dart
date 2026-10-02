import 'package:flutter/material.dart';

import '../services/device_performance.dart';
import '../theme/plezzant/plezzant_tokens.dart';

Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    // Keep the route translucent because some routes composite above video.
    opaque: false,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: PlezzantMotion.standard,
        reverseCurve: PlezzantMotion.exit,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero).animate(curved),
          child: ScaleTransition(scale: Tween<double>(begin: 0.992, end: 1.0).animate(curved), child: child),
        ),
      );
    },
    transitionDuration: DevicePerformance.reducedDuration(PlezzantMotion.route),
    reverseTransitionDuration: DevicePerformance.reducedDuration(PlezzantMotion.routeOut),
  );
}
