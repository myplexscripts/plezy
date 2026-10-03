import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/platform_detector.dart';
import '../theme/plezzant/plezzant_tokens.dart';
import '../theme/plezzant/plezzant_typography.dart';

/// Share of the viewport a TV list column occupies; the rest is split evenly
/// either side so settings-style lists read as a centred column, like tvOS.
const double tvReadableWidthFactor = 0.70;

/// Centres [sliver] in a readable column on TV; a pass-through elsewhere.
class TvReadableSliver extends StatelessWidget {
  final Widget sliver;
  final double widthFactor;

  const TvReadableSliver({super.key, required this.sliver, this.widthFactor = tvReadableWidthFactor});

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isTV()) return sliver;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.crossAxisExtent;
        final inset = math.max(PlezzantTv.safeX, (extent - extent * widthFactor) / 2);
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          sliver: sliver,
        );
      },
    );
  }
}

/// The large centred page title TV list pages show instead of an app bar.
class TvPageTitleSliver extends StatelessWidget {
  final Widget title;

  const TvPageTitleSliver({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(PlezzantTv.safeX, 48, PlezzantTv.safeX, 24),
        child: Center(
          child: DefaultTextStyle.merge(
            style: PlezzantTvType.screenTitle.copyWith(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
            child: title,
          ),
        ),
      ),
    );
  }
}
