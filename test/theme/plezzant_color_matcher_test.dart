import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/plezzant/artwork_color_extractor.dart';
import 'package:plezy/theme/plezzant/plezzant_color_matcher.dart';
import 'package:plezy/theme/plezzant/plezzant_palette.dart';

void main() {
  group('deltaE2000', () {
    // Reference pairs from Sharma, Wu & Dalal (2005), table 1.
    final pairs = <(LabColor, LabColor, double)>[
      (const LabColor(50, 2.6772, -79.7751), const LabColor(50, 0, -82.7485), 2.0425),
      (const LabColor(50, 3.1571, -77.2803), const LabColor(50, 0, -82.7485), 2.8615),
      (const LabColor(50, 2.5, 0), const LabColor(50, 0, -2.5), 4.3065),
      (const LabColor(50, 2.5, 0), const LabColor(73, 25, -18), 27.1492),
      (const LabColor(60.2574, -34.0099, 36.2677), const LabColor(60.4626, -34.1751, 39.4387), 1.2644),
      (const LabColor(2.0776, 0.0795, -1.1350), const LabColor(0.9033, -0.0636, -0.5514), 0.9082),
    ];
    for (final (a, b, expected) in pairs) {
      test('$a vs $b', () {
        expect(deltaE2000(a, b), closeTo(expected, 1e-4));
        expect(deltaE2000(b, a), closeTo(expected, 1e-4));
      });
    }
  });

  group('LabColor.fromColor', () {
    test('white and black hit the L* extremes', () {
      final white = LabColor.fromColor(const Color(0xFFFFFFFF));
      final black = LabColor.fromColor(const Color(0xFF000000));
      expect(white.l, closeTo(100, 0.01));
      expect(white.chroma, lessThan(0.01));
      expect(black.l, closeTo(0, 0.01));
    });

    test('pure sRGB red matches the published Lab value', () {
      final red = LabColor.fromColor(const Color(0xFFFF0000));
      expect(red.l, closeTo(53.24, 0.05));
      expect(red.a, closeTo(80.09, 0.05));
      expect(red.b, closeTo(67.20, 0.05));
    });
  });

  group('PlezzantColorMatcher', () {
    test('every palette entry matches itself with zero distance', () {
      for (final hue in PlezzantPalette.all) {
        for (final shade in PlezzantShade.values) {
          final match = PlezzantColorMatcher.match(hue.shade(shade));
          expect(match.deltaE, closeTo(0, 1e-9), reason: '${hue.name}/$shade');
          expect(match.nearestColor, hue.shade(shade));
        }
      }
    });

    test('an arbitrary green snaps into the green families', () {
      final greens = {
        PlezzantPalette.leafGreen,
        PlezzantPalette.darkTeal,
        PlezzantPalette.deepForest,
        PlezzantPalette.turquoise,
        PlezzantPalette.mint,
      };
      for (final source in const [Color(0xFF3CAA3C), Color(0xFF2E8B57), Color(0xFF66CC88), Color(0xFF1E5A46)]) {
        expect(greens, contains(PlezzantColorMatcher.match(source).hue), reason: '$source');
      }
      expect(PlezzantColorMatcher.match(const Color(0xFF50C83C)).hue, PlezzantPalette.leafGreen);
      expect(PlezzantColorMatcher.match(const Color(0xFF008C8C)).hue, PlezzantPalette.darkTeal);
    });

    test('blues, reds and purples land in their families', () {
      expect(PlezzantColorMatcher.match(const Color(0xFF1E5ADC)).hue, PlezzantPalette.cobalt);
      expect(PlezzantColorMatcher.match(const Color(0xFFD81E3C)).hue, PlezzantPalette.crimson);
      expect(PlezzantColorMatcher.match(const Color(0xFF8732FF)).hue, PlezzantPalette.violet);
      expect(PlezzantColorMatcher.match(const Color(0xFFFFB400)).hue, PlezzantPalette.amber);
    });

    test('dark sources report a darker nearest shade', () {
      final match = PlezzantColorMatcher.match(const Color(0xFF0A3228));
      expect(match.hue, PlezzantPalette.deepForest);
      expect(match.nearestShade, PlezzantShade.darker);
    });

    test('near-neutral colours stay neutral', () {
      for (final grey in const [Color(0xFF000000), Color(0xFF808080), Color(0xFFFFFFFF), Color(0xFF2A2B2D)]) {
        expect(PlezzantColorMatcher.matchOrNull(grey), isNull, reason: '$grey');
      }
      expect(PlezzantColorMatcher.matchOrNull(null), isNull);
    });

    test('matcher output is always an approved colour', () {
      for (var r = 0; r < 256; r += 51) {
        for (var g = 0; g < 256; g += 51) {
          for (var b = 0; b < 256; b += 51) {
            final match = PlezzantColorMatcher.match(Color.fromARGB(255, r, g, b));
            for (final shade in PlezzantShade.values) {
              expect(PlezzantColorMatcher.isApproved(match.shade(shade)), isTrue);
            }
          }
        }
      }
    });

    test('semantic colours are exact palette entries', () {
      const semantic = [
        PlezzantColors.progress,
        PlezzantColors.danger,
        PlezzantColors.dangerSoft,
        PlezzantColors.live,
        PlezzantColors.success,
        PlezzantColors.automation,
        PlezzantColors.warning,
        PlezzantColors.info,
        PlezzantColors.highlight,
        PlezzantColors.highlightDeep,
        PlezzantColors.rating,
        PlezzantColors.favorite,
      ];
      for (final color in semantic) {
        expect(PlezzantColorMatcher.match(color).deltaE, closeTo(0, 1e-9), reason: '$color');
      }
    });

    test('isApproved rejects off-palette chroma and accepts neutrals', () {
      expect(PlezzantColorMatcher.isApproved(const Color(0xFF00FF00)), isFalse);
      expect(PlezzantColorMatcher.isApproved(const Color(0x80FFFFFF)), isTrue);
      expect(PlezzantColorMatcher.isApproved(PlezzantPalette.azure.original.withValues(alpha: 0.3)), isTrue);
    });
  });

  group('ArtworkColorExtractor.dominantColor', () {
    Uint8List image(List<(Color, int)> runs) {
      final bytes = <int>[];
      for (final (color, count) in runs) {
        for (var i = 0; i < count; i++) {
          bytes.addAll([(color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round(), 255]);
        }
      }
      return Uint8List.fromList(bytes);
    }

    test('a vivid subject beats a large dark background', () {
      final pixels = image([(const Color(0xFF080808), 900), (const Color(0xFF1E5ADC), 100)]);
      final dominant = ArtworkColorExtractor.dominantColor(pixels)!;
      expect(PlezzantColorMatcher.match(dominant).hue, PlezzantPalette.cobalt);
    });

    test('fully transparent artwork yields null', () {
      expect(ArtworkColorExtractor.dominantColor(Uint8List(400)), isNull);
    });

    test('grey artwork stays neutral after matching', () {
      final pixels = image([(const Color(0xFF777777), 500)]);
      expect(PlezzantColorMatcher.matchOrNull(ArtworkColorExtractor.dominantColor(pixels)), isNull);
    });
  });
}
