import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/main.dart' as app;
import 'package:plezy/services/device_performance.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/plezzant/plezzant_tokens.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/tv_reference_scale.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  group('reference canvas', () {
    test('a Google TV (960x540) maps reference units at 0.5 with no comfort floor', () {
      expect(PlezzantTv.scaleForHeight(540), 0.5);
      expect(PlezzantTv.scaleForHeight(1080), 1.0);
      // The old 0.85 floor is what rendered the TV UI oversized.
      expect(PlezzantTv.scaleForHeight(480), lessThan(0.85));
    });

    test('Android TV surfaces normalise onto the 540-tall canvas', () {
      expect(app.FormFactorScale.tvSurfaceScaleFor(const Size(960, 540)), 1.0);
      // mdpi boxes and desktop "force TV" windows report 1080 logical rows.
      expect(app.FormFactorScale.tvSurfaceScaleFor(const Size(1920, 1080)), 2.0);
      // Within 5% is left alone rather than resampled.
      expect(app.FormFactorScale.tvSurfaceScaleFor(const Size(1000, 560)), 1.0);
    });

    testWidgets('TvReferenceScale lays its child out in reference units', (tester) async {
      TvDetectionService.debugSetAppleTVOverride(true);
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      late double innerScale;
      final box = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: TvReferenceScale(
              child: Builder(
                builder: (context) {
                  innerScale = PlezzantTv.scaleOf(context);
                  return SizedBox(key: box, width: PlezzantTv.sidebarWidth, height: 100);
                },
              ),
            ),
          ),
        ),
      );

      expect(innerScale, 1.0);
      // Laid out at 336 reference units, painted at 168 device pixels.
      expect(tester.getSize(find.byKey(box)).width, PlezzantTv.sidebarWidth);
      expect(tester.getRect(find.byKey(box)).width, closeTo(PlezzantTv.sidebarWidth / 2, 0.01));
    });
  });

  group('effects and accessibility policy', () {
    test('glass keeps its full blur before the device tier is known', () {
      expect(DevicePerformance.isReduced, isFalse);
      expect(DevicePerformance.isBalanced, isFalse);
      expect(DevicePerformance.maxGlassBlur, double.infinity);
    });

    testWidgets('frame timing graph is opt-in from settings', (tester) async {
      await SettingsService.getInstance();
      Widget shell() => MaterialApp(builder: (context, child) => app.rootShell(child), home: const SizedBox());

      await tester.pumpWidget(shell());
      expect(find.byType(PerformanceOverlay), findsNothing);

      await SettingsService.instance.write(SettingsService.showFrameTimingOverlay, true);
      await tester.pump();
      expect(find.byType(PerformanceOverlay), findsOneWidget);
    });
  });
}
