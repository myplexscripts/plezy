import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'plezzant_palette.dart';

/// A colour in CIE L*a*b* (D65 white point).
class LabColor {
  final double l;
  final double a;
  final double b;

  const LabColor(this.l, this.a, this.b);

  /// CIE LCh chroma.
  double get chroma => math.sqrt(a * a + b * b);

  factory LabColor.fromColor(Color color) {
    double lin(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    final r = lin(color.r);
    final g = lin(color.g);
    final bl = lin(color.b);

    // sRGB (D65) -> XYZ, normalised by the D65 reference white.
    final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * bl) / 0.95047;
    final y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * bl) / 1.00000;
    final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * bl) / 1.08883;

    double f(double t) => t > 216 / 24389 ? math.pow(t, 1 / 3).toDouble() : (24389 / 27 * t + 16) / 116;
    final fx = f(x);
    final fy = f(y);
    final fz = f(z);
    return LabColor(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
  }

  @override
  String toString() => 'Lab(${l.toStringAsFixed(1)}, ${a.toStringAsFixed(1)}, ${b.toStringAsFixed(1)})';
}

/// CIEDE2000 colour difference (Sharma, Wu & Dalal 2005 formulation).
double deltaE2000(LabColor c1, LabColor c2) {
  const kL = 1.0, kC = 1.0, kH = 1.0;
  double deg(double rad) => rad * 180 / math.pi;
  double rad(double deg) => deg * math.pi / 180;

  final cBar = (c1.chroma + c2.chroma) / 2;
  final cBar7 = math.pow(cBar, 7).toDouble();
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + 6103515625.0))); // 25^7
  final a1p = (1 + g) * c1.a;
  final a2p = (1 + g) * c2.a;
  final c1p = math.sqrt(a1p * a1p + c1.b * c1.b);
  final c2p = math.sqrt(a2p * a2p + c2.b * c2.b);

  double hueAngle(double b, double ap) {
    if (b == 0 && ap == 0) return 0;
    final h = deg(math.atan2(b, ap));
    return h < 0 ? h + 360 : h;
  }

  final h1p = hueAngle(c1.b, a1p);
  final h2p = hueAngle(c2.b, a2p);

  final dLp = c2.l - c1.l;
  final dCp = c2p - c1p;
  double dhp;
  if (c1p * c2p == 0) {
    dhp = 0;
  } else if ((h2p - h1p).abs() <= 180) {
    dhp = h2p - h1p;
  } else if (h2p - h1p > 180) {
    dhp = h2p - h1p - 360;
  } else {
    dhp = h2p - h1p + 360;
  }
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(rad(dhp / 2));

  final lBarP = (c1.l + c2.l) / 2;
  final cBarP = (c1p + c2p) / 2;
  double hBarP;
  if (c1p * c2p == 0) {
    hBarP = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBarP = (h1p + h2p) / 2;
  } else if (h1p + h2p < 360) {
    hBarP = (h1p + h2p + 360) / 2;
  } else {
    hBarP = (h1p + h2p - 360) / 2;
  }

  final t =
      1 -
      0.17 * math.cos(rad(hBarP - 30)) +
      0.24 * math.cos(rad(2 * hBarP)) +
      0.32 * math.cos(rad(3 * hBarP + 6)) -
      0.20 * math.cos(rad(4 * hBarP - 63));
  final dTheta = 30 * math.exp(-math.pow((hBarP - 275) / 25, 2));
  final cBarP7 = math.pow(cBarP, 7).toDouble();
  final rC = 2 * math.sqrt(cBarP7 / (cBarP7 + 6103515625.0));
  final lMinus50Sq = math.pow(lBarP - 50, 2);
  final sL = 1 + (0.015 * lMinus50Sq) / math.sqrt(20 + lMinus50Sq);
  final sC = 1 + 0.045 * cBarP;
  final sH = 1 + 0.015 * cBarP * t;
  final rT = -math.sin(rad(2 * dTheta)) * rC;

  final lTerm = dLp / (kL * sL);
  final cTerm = dCp / (kC * sC);
  final hTerm = dHp / (kH * sH);
  return math.sqrt(lTerm * lTerm + cTerm * cTerm + hTerm * hTerm + rT * cTerm * hTerm);
}

/// The result of snapping an arbitrary colour onto the Plezzant palette.
class PlezzantColorMatch {
  final PlezzantHue hue;

  /// The shade whose Lab value sat closest to the source colour.
  final PlezzantShade nearestShade;

  /// CIEDE2000 distance from the source to [nearestShade] of [hue].
  final double deltaE;

  const PlezzantColorMatch({required this.hue, required this.nearestShade, required this.deltaE});

  Color get nearestColor => hue.shade(nearestShade);

  Color shade(PlezzantShade shade) => hue.shade(shade);

  @override
  String toString() => 'PlezzantColorMatch(${hue.name}/${nearestShade.name}, ΔE=${deltaE.toStringAsFixed(2)})';
}

/// The single place where dynamic colour becomes interface colour.
///
/// Every colour that comes from artwork, channel logos, dominant-colour
/// analysis or any other dynamic source must pass through [match] (or
/// [matchOrNull]); screens never paint an extracted RGB value directly.
abstract final class PlezzantColorMatcher {
  /// Below this L*a*b* chroma a source reads as grey: snapping it to a hue
  /// would invent colour that is not in the artwork, so [matchOrNull] returns
  /// null and callers fall back to neutral structure.
  static const double neutralChromaThreshold = 9.0;

  static final List<(PlezzantHue, PlezzantShade, LabColor)> _entries = [
    for (final hue in PlezzantPalette.all)
      for (final shade in PlezzantShade.values) (hue, shade, LabColor.fromColor(hue.shade(shade))),
  ];

  /// Closest palette entry by CIEDE2000 across all 78 hue × shade entries.
  static PlezzantColorMatch match(Color source) {
    final lab = LabColor.fromColor(source);
    var best = _entries.first;
    var bestDelta = double.infinity;
    for (final entry in _entries) {
      final d = deltaE2000(lab, entry.$3);
      if (d < bestDelta) {
        bestDelta = d;
        best = entry;
      }
    }
    return PlezzantColorMatch(hue: best.$1, nearestShade: best.$2, deltaE: bestDelta);
  }

  /// Like [match], but returns null for near-neutral sources (greys, black,
  /// white) so they keep the neutral structural treatment.
  static PlezzantColorMatch? matchOrNull(Color? source) {
    if (source == null) return null;
    if (LabColor.fromColor(source).chroma < neutralChromaThreshold) return null;
    return match(source);
  }

  /// Convenience: snap [source] and return the requested [shade] directly.
  static Color snap(Color source, {required PlezzantShade shade}) => match(source).shade(shade);

  /// Whether [color] (alpha ignored) is an exact palette colour or a neutral.
  /// Used by tests and debug assertions to keep off-palette colour out.
  static bool isApproved(Color color) {
    final opaque = color.withAlpha(0xFF);
    if (LabColor.fromColor(opaque).chroma < 2.5) return true;
    for (final hue in PlezzantPalette.all) {
      for (final shade in PlezzantShade.values) {
        if (hue.shade(shade).toARGB32() == opaque.toARGB32()) return true;
      }
    }
    return false;
  }
}
