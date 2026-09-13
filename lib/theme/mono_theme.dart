import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'gapped_track_shape.dart';
import 'mono_tokens.dart';

final Map<({bool dark, bool oled, TargetPlatform platform}), ThemeData> _monoThemeCache = {};

ThemeData monoTheme({required bool dark, bool oled = false}) {
  final key = (dark: dark || oled, oled: oled, platform: defaultTargetPlatform);
  final cached = _monoThemeCache[key];
  if (cached != null) return cached;

  final theme = _buildMonoTheme(dark: key.dark, oled: key.oled, platform: key.platform);
  _monoThemeCache[key] = theme;
  return theme;
}

ThemeData _buildMonoTheme({required bool dark, required bool oled, required TargetPlatform platform}) {
  final ({Color bg, Color surface, Color outline, Color text, Color textMuted}) c;
  if (oled) {
    c = (
      bg: const Color(0xFF000000),
      surface: const Color(0xFF0B0B0D),
      outline: const Color(0x20FFFFFF),
      text: const Color(0xFFF5F5F7),
      textMuted: const Color(0xA6F5F5F7),
    );
  } else if (dark) {
    c = (
      bg: const Color(0xFF050506),
      surface: const Color(0xFF111113),
      outline: const Color(0x20FFFFFF),
      text: const Color(0xFFF5F5F7),
      textMuted: const Color(0xA6F5F5F7),
    );
  } else {
    c = (
      bg: const Color(0xFFF5F5F7),
      surface: const Color(0xFFFFFFFF),
      outline: const Color(0x18000000),
      text: const Color(0xFF111113),
      textMuted: const Color(0x99111113),
    );
  }

  final isDark = dark || oled;
  final clickableCursor = WidgetStateProperty.resolveWith<MouseCursor>(
    (states) => states.contains(WidgetState.disabled) ? MouseCursor.defer : SystemMouseCursors.click,
  );

  final buttonStyle = ButtonStyle(
    mouseCursor: clickableCursor,
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(c.text),
    foregroundColor: WidgetStatePropertyAll(isDark ? c.bg : Colors.white),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
  );

  final textTheme = Typography.englishLike2021
      .apply(fontFamily: 'Inter', bodyColor: c.text, displayColor: c.text)
      .copyWith(
        displayLarge: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 56,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          height: 1.02,
        ),
        displayMedium: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 46,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.15,
          height: 1.04,
        ),
        displaySmall: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
          height: 1.06,
        ),
        headlineLarge: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
        ),
        headlineMedium: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.55,
        ),
        titleLarge: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: c.text,
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: c.textMuted,
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
      );

  final base = ThemeData(
    platform: platform,
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: c.text,
      onPrimary: isDark ? c.bg : Colors.white,
      secondary: c.text,
      onSecondary: c.bg,
      surface: c.surface,
      onSurface: c.text,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      tertiary: c.text,
      onTertiary: c.bg,
      primaryContainer: c.surface,
      onPrimaryContainer: c.text,
      secondaryContainer: c.surface,
      onSecondaryContainer: c.text,
      surfaceContainerHighest: c.surface,
      surfaceContainerLow: c.bg,
      surfaceDim: c.bg,
      surfaceBright: c.surface,
      outline: c.outline,
      shadow: Colors.transparent,
      scrim: Colors.black,
      inverseSurface: c.text,
      onInverseSurface: c.bg,
      inversePrimary: c.bg,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    focusColor: c.text.withValues(alpha: 0.14),
    hoverColor: c.text.withValues(alpha: 0.06),
    dividerColor: c.outline,
    scaffoldBackgroundColor: c.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.text,
      titleTextStyle: TextStyle(
        color: c.text,
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
      ),
    ),
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
    inputDecorationTheme: _inputDecorationTheme(c.text, c.textMuted),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    iconButtonTheme: IconButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    sliderTheme: SliderThemeData(
      inactiveTrackColor: c.text.withValues(alpha: 0.12),
      trackHeight: 16,
      trackGap: 6,
      thumbSize: const WidgetStatePropertyAll(Size(4, 20)),
      thumbShape: const HandleThumbShape(),
      trackShape: const GappedTrackShape(),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
      year2023: false,
    ),
    dividerTheme: DividerThemeData(space: 0, thickness: 1, color: c.outline),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: c.text,
      textColor: c.text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: c.textMuted, fontFamily: 'Inter', fontSize: 12)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(opacity: active ? 1 : 0.62, size: 22, color: c.text);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surface,
      contentTextStyle: TextStyle(color: c.text, fontFamily: 'Inter'),
      actionTextColor: c.text,
      elevation: 6,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      insetPadding: const EdgeInsets.all(16),
    ),
  );

  return base.copyWith(
    extensions: [
      MonoTokens(
        radiusSm: 10,
        radiusMd: 16,
        radiusLg: 24,
        radiusXs: 6,
        groupGap: 3,
        space: 16,
        fast: const Duration(milliseconds: 160),
        normal: const Duration(milliseconds: 220),
        slow: const Duration(milliseconds: 320),
        expressive: const Duration(milliseconds: 380),
        bg: c.bg,
        surface: c.surface,
        outline: c.outline,
        text: c.text,
        textMuted: c.textMuted,
      ),
    ],
  );
}

InputDecorationTheme _inputDecorationTheme(Color text, Color textMuted) {
  final unfocusedFill = text.withValues(alpha: 0.08);
  final focusedFill = text.withValues(alpha: 0.16);
  const border = OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none);
  return InputDecorationTheme(
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.focused) ? focusedFill : unfocusedFill,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    hintStyle: TextStyle(color: textMuted, fontFamily: 'Inter'),
  );
}
