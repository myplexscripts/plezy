import 'package:flutter/material.dart';

import 'plezzant_tokens.dart';

/// The one Plezzant type scale. Every text style in the app derives from
/// these roles through `Theme.of(context).textTheme`; screens must not invent
/// sizes. Nothing renders below [minimumSize] logical pixels.
abstract final class PlezzantType {
  static const String family = 'Inter';

  /// Floor for any interface text (10-foot legibility).
  static const double minimumSize = 14;

  /// Display: hero titles when no clear-logo artwork exists.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: family,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
    height: 1.04,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: family,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.06,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: family,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    height: 1.1,
  );

  /// Headlines: screen titles, detail-page titles.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.15,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.45,
    height: 1.18,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  /// Titles: shelf headers, card titles, dialog titles.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.25,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
  );
  static const TextStyle titleSmall = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  /// List and settings row titles.
  static const TextStyle listTitle = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  /// Body: synopsis, descriptions, settings explanations.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05,
    height: 1.4,
  );

  /// Labels: buttons, chips, metadata, badges.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.05,
    height: 1.2,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
  );

  /// Builds the Material [TextTheme] from the Plezzant roles.
  static TextTheme textTheme({required Color text, required Color muted}) => TextTheme(
    displayLarge: displayLarge.copyWith(color: text),
    displayMedium: displayMedium.copyWith(color: text),
    displaySmall: displaySmall.copyWith(color: text),
    headlineLarge: headlineLarge.copyWith(color: text),
    headlineMedium: headlineMedium.copyWith(color: text),
    headlineSmall: headlineSmall.copyWith(color: text),
    titleLarge: titleLarge.copyWith(color: text),
    titleMedium: titleMedium.copyWith(color: text),
    titleSmall: titleSmall.copyWith(color: text),
    bodyLarge: bodyLarge.copyWith(color: text),
    bodyMedium: bodyMedium.copyWith(color: text),
    bodySmall: bodySmall.copyWith(color: muted),
    labelLarge: labelLarge.copyWith(color: text),
    labelMedium: labelMedium.copyWith(color: text),
    labelSmall: labelSmall.copyWith(color: muted),
  );

  /// Clamp an ad-hoc size onto the scale floor. Prefer a [TextTheme] role;
  /// this exists for the few legacy call sites that compute sizes.
  static double atLeastMinimum(double size) => size < minimumSize ? minimumSize : size;
}

/// Television-only type roles for couch-distance legibility.
///
/// The shared Material text theme remains compact for desktop and mobile.
/// Large-screen surfaces opt into these roles explicitly.
abstract final class PlezzantTvType {
  static const String family = PlezzantType.family;

  /// Converts a reference-canvas role to device pixels (see
  /// [PlezzantTv.scaleOf]); a no-op inside a `TvReferenceScale`.
  static TextStyle of(BuildContext context, TextStyle role) =>
      role.copyWith(fontSize: role.fontSize! * PlezzantTv.scaleOf(context));

  /// Secondary line under a card title.
  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const TextStyle hero = TextStyle(
    fontFamily: family,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.05,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: family,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    height: 1.08,
  );

  static const TextStyle shelfTitle = TextStyle(
    fontFamily: family,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    height: 1.12,
  );

  static const TextStyle navigation = TextStyle(
    fontFamily: family,
    fontSize: 23,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.15,
  );

  static const TextStyle navigationSelected = TextStyle(
    fontFamily: family,
    fontSize: 23,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.15,
  );

  static const TextStyle navigationSecondary = TextStyle(
    fontFamily: family,
    fontSize: 19,
    fontWeight: FontWeight.w500,
    height: 1.15,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(fontFamily: family, fontSize: 24, fontWeight: FontWeight.w400, height: 1.35);

  static const TextStyle metadata = TextStyle(
    fontFamily: family,
    fontSize: 23,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
