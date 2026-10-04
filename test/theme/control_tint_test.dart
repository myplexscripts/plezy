import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/plezzant/control_tint.dart';
import 'package:plezy/theme/plezzant/ultra_blur.dart';

void main() {
  test('controls take the complement of the bottom-left blur colour', () {
    // Deep blue corner → warm (yellow/orange) controls.
    final blue = UltraBlurColors(
      const Color(0xFF1C2A66),
      const Color(0xFF1C2A66),
      const Color(0xFF1C2A66),
      const Color(0xFF101020),
    );
    final hue = HSLColor.fromColor(ControlTints.fromBlur(blue).accent).hue;
    expect(hue, inInclusiveRange(30, 80));
  });

  test('grey corners fall back to the brand tint', () {
    const grey = UltraBlurColors(Color(0xFF202020), Color(0xFF202020), Color(0xFF202020), Color(0xFF202020));
    expect(ControlTints.fromBlur(grey).accent, ControlTints.fallback.accent);
    expect(ControlTints.fromBlur(null).accent, ControlTints.fallback.accent);
  });

  test('focused fill is near-white and its label stays dark', () {
    final tints = ControlTints.fromBlur(null);
    expect(HSLColor.fromColor(tints.focusFill).lightness, greaterThan(0.9));
    expect(HSLColor.fromColor(tints.focusForeground).lightness, lessThan(0.2));
  });
}
