import 'package:flutter/painting.dart';

/// Which of the three fixed shades of a [PlezzantHue] a surface uses.
///
/// Matching (see `PlezzantColorMatcher`) decides the hue family; the role of
/// the surface decides the shade. Ambient backgrounds sit on [darker], focus
/// tints and text-adjacent highlights on [lighter], indicators on [original].
enum PlezzantShade { lighter, original, darker }

/// One entry of the fixed Plezzant chromatic palette.
///
/// These 26 families × 3 shades are the only chromatic colours the interface
/// may paint. Anything extracted from artwork is mapped onto this table first.
class PlezzantHue {
  final String name;
  final Color lighter;
  final Color original;
  final Color darker;

  const PlezzantHue._(this.name, this.lighter, this.original, this.darker);

  Color shade(PlezzantShade shade) => switch (shade) {
    PlezzantShade.lighter => lighter,
    PlezzantShade.original => original,
    PlezzantShade.darker => darker,
  };

  @override
  String toString() => 'PlezzantHue($name)';
}

/// The fixed Plezzant palette. Do not add colours here without a design
/// decision; the colour matcher treats this list as the whole chromatic gamut.
abstract final class PlezzantPalette {
  static const crimson = PlezzantHue._(
    'Crimson',
    Color.fromARGB(0xFF, 245, 115, 135),
    Color.fromARGB(0xFF, 220, 20, 60),
    Color.fromARGB(0xFF, 150, 10, 40),
  );
  static const deepBerry = PlezzantHue._(
    'Deep Berry',
    Color.fromARGB(0xFF, 240, 95, 125),
    Color.fromARGB(0xFF, 190, 10, 55),
    Color.fromARGB(0xFF, 120, 5, 35),
  );
  static const persimmon = PlezzantHue._(
    'Persimmon',
    Color.fromARGB(0xFF, 253, 165, 140),
    Color.fromARGB(0xFF, 238, 80, 5),
    Color.fromARGB(0xFF, 165, 45, 25),
  );
  static const burntOrange = PlezzantHue._(
    'Burnt Orange',
    Color.fromARGB(0xFF, 235, 150, 110),
    Color.fromARGB(0xFF, 200, 80, 45),
    Color.fromARGB(0xFF, 135, 45, 20),
  );
  static const coral = PlezzantHue._(
    'Coral',
    Color.fromARGB(0xFF, 255, 175, 145),
    Color.fromARGB(0xFF, 255, 110, 75),
    Color.fromARGB(0xFF, 185, 60, 35),
  );
  static const apricot = PlezzantHue._(
    'Apricot',
    Color.fromARGB(0xFF, 255, 215, 185),
    Color.fromARGB(0xFF, 255, 155, 110),
    Color.fromARGB(0xFF, 195, 95, 60),
  );
  static const amber = PlezzantHue._(
    'Amber',
    Color.fromARGB(0xFF, 255, 225, 105),
    Color.fromARGB(0xFF, 255, 180, 0),
    Color.fromARGB(0xFF, 180, 120, 0),
  );
  static const brightGold = PlezzantHue._(
    'Bright Gold',
    Color.fromARGB(0xFF, 255, 235, 125),
    Color.fromARGB(0xFF, 255, 200, 0),
    Color.fromARGB(0xFF, 185, 140, 0),
  );
  static const ochre = PlezzantHue._(
    'Ochre',
    Color.fromARGB(0xFF, 245, 220, 145),
    Color.fromARGB(0xFF, 225, 175, 70),
    Color.fromARGB(0xFF, 160, 115, 30),
  );
  static const leafGreen = PlezzantHue._(
    'Leaf Green',
    Color.fromARGB(0xFF, 170, 235, 145),
    Color.fromARGB(0xFF, 90, 215, 70),
    Color.fromARGB(0xFF, 55, 145, 40),
  );
  static const darkTeal = PlezzantHue._(
    'Dark Teal',
    Color.fromARGB(0xFF, 125, 205, 205),
    Color.fromARGB(0xFF, 0, 145, 145),
    Color.fromARGB(0xFF, 0, 95, 95),
  );
  static const deepForest = PlezzantHue._(
    'Deep Forest',
    Color.fromARGB(0xFF, 145, 180, 170),
    Color.fromARGB(0xFF, 20, 80, 65),
    Color.fromARGB(0xFF, 10, 50, 40),
  );
  static const turquoise = PlezzantHue._(
    'Turquoise',
    Color.fromARGB(0xFF, 180, 245, 225),
    Color.fromARGB(0xFF, 45, 200, 170),
    Color.fromARGB(0xFF, 25, 135, 112),
  );
  static const mint = PlezzantHue._(
    'Mint',
    Color.fromARGB(0xFF, 195, 250, 230),
    Color.fromARGB(0xFF, 35, 205, 155),
    Color.fromARGB(0xFF, 20, 140, 102),
  );
  static const skyBlue = PlezzantHue._(
    'Sky Blue',
    Color.fromARGB(0xFF, 180, 225, 245),
    Color.fromARGB(0xFF, 60, 165, 225),
    Color.fromARGB(0xFF, 40, 115, 165),
  );
  static const azure = PlezzantHue._(
    'Azure',
    Color.fromARGB(0xFF, 160, 225, 255),
    Color.fromARGB(0xFF, 30, 180, 255),
    Color.fromARGB(0xFF, 15, 115, 185),
  );
  static const cobalt = PlezzantHue._(
    'Cobalt',
    Color.fromARGB(0xFF, 130, 175, 255),
    Color.fromARGB(0xFF, 30, 90, 220),
    Color.fromARGB(0xFF, 15, 55, 150),
  );
  static const cornflower = PlezzantHue._(
    'Cornflower',
    Color.fromARGB(0xFF, 195, 215, 255),
    Color.fromARGB(0xFF, 115, 155, 245),
    Color.fromARGB(0xFF, 75, 105, 185),
  );
  static const navyIndigo = PlezzantHue._(
    'Navy Indigo',
    Color.fromARGB(0xFF, 170, 165, 195),
    Color.fromARGB(0xFF, 75, 65, 120),
    Color.fromARGB(0xFF, 45, 35, 80),
  );
  static const violet = PlezzantHue._(
    'Violet',
    Color.fromARGB(0xFF, 210, 175, 255),
    Color.fromARGB(0xFF, 135, 50, 255),
    Color.fromARGB(0xFF, 85, 20, 180),
  );
  static const vividPurple = PlezzantHue._(
    'Vivid Purple',
    Color.fromARGB(0xFF, 230, 205, 250),
    Color.fromARGB(0xFF, 185, 135, 230),
    Color.fromARGB(0xFF, 120, 80, 165),
  );
  static const softLilac = PlezzantHue._(
    'Soft Lilac',
    Color.fromARGB(0xFF, 242, 230, 252),
    Color.fromARGB(0xFF, 215, 190, 245),
    Color.fromARGB(0xFF, 145, 115, 180),
  );
  static const plum = PlezzantHue._(
    'Plum',
    Color.fromARGB(0xFF, 205, 160, 185),
    Color.fromARGB(0xFF, 135, 55, 105),
    Color.fromARGB(0xFF, 85, 25, 65),
  );
  static const magenta = PlezzantHue._(
    'Magenta',
    Color.fromARGB(0xFF, 255, 165, 220),
    Color.fromARGB(0xFF, 225, 20, 135),
    Color.fromARGB(0xFF, 150, 10, 85),
  );
  static const hotPink = PlezzantHue._(
    'Hot Pink',
    Color.fromARGB(0xFF, 255, 195, 225),
    Color.fromARGB(0xFF, 255, 128, 185),
    Color.fromARGB(0xFF, 180, 60, 115),
  );
  static const dustyPink = PlezzantHue._(
    'Dusty Pink',
    Color.fromARGB(0xFF, 255, 225, 230),
    Color.fromARGB(0xFF, 255, 185, 198),
    Color.fromARGB(0xFF, 205, 125, 140),
  );

  static final List<PlezzantHue> all = List.unmodifiable([
    crimson,
    deepBerry,
    persimmon,
    burntOrange,
    coral,
    apricot,
    amber,
    brightGold,
    ochre,
    leafGreen,
    darkTeal,
    deepForest,
    turquoise,
    mint,
    skyBlue,
    azure,
    cobalt,
    cornflower,
    navyIndigo,
    violet,
    vividPurple,
    softLilac,
    plum,
    magenta,
    hotPink,
    dustyPink,
  ]);

  /// Brand accent used when no artwork context exists (startup, settings).
  static const PlezzantHue brand = crimson;

  /// Semantic hues. Status colours still come from the palette so error and
  /// success states never introduce an off-palette chromatic colour.
  static const PlezzantHue danger = crimson;
  static const PlezzantHue warning = amber;
  static const PlezzantHue success = mint;
  static const PlezzantHue rating = brightGold;
  static const PlezzantHue live = crimson;
  static const PlezzantHue favorite = deepBerry;
}

/// Semantic, const palette colours for status and state. Use these instead of
/// Material swatches (`Colors.red`, `Colors.amber`, …) anywhere in the UI.
abstract final class PlezzantColors {
  /// Watch progress on cards and lists (brand hue, so progress reads the same
  /// on every screen regardless of ambience).
  static const Color progress = Color.fromARGB(0xFF, 220, 20, 60); // Crimson

  /// Destructive actions, errors, failed states.
  static const Color danger = Color.fromARGB(0xFF, 220, 20, 60); // Crimson
  static const Color dangerSoft = Color.fromARGB(0xFF, 245, 115, 135); // Crimson lighter

  /// Live / recording indicators.
  static const Color live = Color.fromARGB(0xFF, 220, 20, 60); // Crimson

  /// Successful / connected / complete states.
  static const Color success = Color.fromARGB(0xFF, 35, 205, 155); // Mint

  /// Enabled automation (sync rules, schedules).
  static const Color automation = Color.fromARGB(0xFF, 45, 200, 170); // Turquoise

  /// Pending or attention-needed states.
  static const Color warning = Color.fromARGB(0xFF, 238, 80, 5); // Persimmon

  /// Informational / in-progress states.
  static const Color info = Color.fromARGB(0xFF, 30, 180, 255); // Azure

  /// Active toggles and highlighted options inside player menus.
  static const Color highlight = Color.fromARGB(0xFF, 255, 180, 0); // Amber
  static const Color highlightDeep = Color.fromARGB(0xFF, 180, 120, 0); // Amber darker

  /// Star ratings.
  static const Color rating = Color.fromARGB(0xFF, 255, 200, 0); // Bright Gold

  /// Favourite / loved state.
  static const Color favorite = Color.fromARGB(0xFF, 240, 95, 125); // Deep Berry lighter
}

/// Neutral structural colours. Permitted alongside the chromatic palette.
abstract final class PlezzantNeutrals {
  static const black = Color(0xFF000000);

  /// App canvas: a warm near-black that lets palette ambience read as light.
  static const canvas = Color(0xFF07070A);
  static const surface = Color(0xFF111116);
  static const surfaceRaised = Color(0xFF1A1A21);
  static const hairline = Color(0x1FFFFFFF);
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFFF4F4F6);
  static const textSecondary = Color(0xB3F4F4F6);
  static const textTertiary = Color(0x80F4F4F6);

  static const lightCanvas = Color(0xFFF4F4F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF111116);
}
