import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/feature_set.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  tearDown(() => TvDetectionService.setForceTVSync(false));

  test('TV offers the everyday set only', () async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    expect(FeatureSet.advanced, isFalse);
  });

  test('other form factors keep power-user options', () async {
    await TvDetectionService.getInstance();
    TvDetectionService.setForceTVSync(false);
    expect(FeatureSet.advanced, !PlatformDetector.isTV());
  });
}
