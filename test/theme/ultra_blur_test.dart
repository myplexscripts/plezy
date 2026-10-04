import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/plezzant/ultra_blur.dart';

void main() {
  group('UltraBlurColors.fromHex', () {
    test('parses the server corners in order', () {
      final colors = UltraBlurColors.fromHex(['1a2b3c', '#203040', '102030', '0f0f2f'])!;
      expect(colors.corners, hasLength(4));
      // Dark inputs pass the readability clamp unchanged in hue.
      expect(HSLColor.fromColor(colors.topLeft).hue, closeTo(HSLColor.fromColor(const Color(0xFF1A2B3C)).hue, 1));
    });

    test('rejects malformed corners', () {
      expect(UltraBlurColors.fromHex(['zzzzzz', '000000', '000000', '000000']), isNull);
      expect(UltraBlurColors.fromHex(['000000', '000000', '000000']), isNull);
      expect(UltraBlurColors.fromHex(['0000', '000000', '000000', '000000']), isNull);
    });

    test('keeps bright artwork dark enough for white text', () {
      final colors = UltraBlurColors.fromHex(['ffffff', 'ffee88', 'ccddff', 'fafafa'])!;
      for (final c in colors.corners) {
        expect(HSLColor.fromColor(c).lightness, lessThanOrEqualTo(0.345));
      }
    });
  });

  test('cornersOf weights each corner toward its own quadrant', () {
    const w = 8, h = 4;
    final pixels = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        // Left half red, right half blue.
        pixels[i] = x < w / 2 ? 200 : 0;
        pixels[i + 2] = x < w / 2 ? 0 : 200;
        pixels[i + 3] = 255;
      }
    }
    final colors = UltraBlurResolver.cornersOf(pixels, w, h)!;
    expect(colors.topLeft.r, greaterThan(colors.topLeft.b));
    expect(colors.topRight.b, greaterThan(colors.topRight.r));
    expect(colors.bottomLeft.r, greaterThan(colors.bottomLeft.b));
    expect(colors.bottomRight.b, greaterThan(colors.bottomRight.r));
  });

  testWidgets('UltraBlurBackground paints fixed colours', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: UltraBlurBackground(colors: UltraBlurColors.fallback),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
