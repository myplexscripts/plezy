import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/plezzant/ultra_blur.dart';

void main() {
  test('readable keeps bright artwork dark enough for white text', () {
    final colors = const UltraBlurColors(
      Color(0xFFFFFFFF),
      Color(0xFFFFEE88),
      Color(0xFFCCDDFF),
      Color(0xFFFAFAFA),
    ).readable();
    for (final c in colors.corners) {
      expect(HSLColor.fromColor(c).lightness, lessThanOrEqualTo(0.345));
    }
  });

  test('fromEdges reads the left side, bottom-left corner and bottom edge', () {
    const w = 20, h = 12;
    final pixels = Uint8List(w * h * 4);
    void put(int x, int y, int r, int g, int b) {
      final i = (y * w + x) * 4;
      pixels[i] = r;
      pixels[i + 1] = g;
      pixels[i + 2] = b;
      pixels[i + 3] = 255;
    }

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        // Left strip red, bottom rows blue, everything else green.
        if (y >= h - 2) {
          put(x, y, 0, 0, 200);
        } else if (x <= 1) {
          put(x, y, 200, 0, 0);
        } else {
          put(x, y, 0, 200, 0);
        }
      }
    }
    final colors = UltraBlurResolver.fromEdges(pixels, w, h)!;
    expect(colors.topLeft.r, greaterThan(colors.topLeft.b));
    expect(colors.topLeft, colors.topRight);
    expect(colors.bottomRight.b, greaterThan(colors.bottomRight.r));
    expect(colors.bottomLeft.b, greaterThan(colors.bottomLeft.g));
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
