import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'gapped_track_shape.dart';
import 'mono_tokens.dart';
import 'plezzant/plezzant_palette.dart';
import 'plezzant/plezzant_tokens.dart';
import 'plezzant/plezzant_typography.dart';

final Map<({bool dark, bool oled, TargetPlatform platform}), ThemeData> _monoThemeCache = {};

ThemeData monoTheme({required bool dark, bool oled = false}) {
  // ThemeData derives several defaults from defaultTargetPlatform.
  final key = (dark: dark || oled, oled: oled, platform: defaultTargetPlatform);
  final cached = _monoThemeCache[key];
  if (cached != null) return cached;

  final theme = _buildMonoTheme(dark: key.dark, oled: key.oled, platform: key.platform);
  _monoThemeCache[key] = theme;
  return theme;
}

ThemeData _buildMonoTheme({required bool dark, required bool oled, required TargetPlatform platform}) {
  // Plezzant neutrals: structure stays achromatic so palette ambience reads
  // as light falling on the interface rather than as paint.
  final ({Color bg, Color surface, Color outline, Color text, Color textMuted}) c;
  if (oled) {
    c = (
      bg: PlezzantNeutrals.black,
      surface: const Color(0xFF0C0C0F),
      outline: PlezzantNeutrals.hairline,
      text: PlezzantNeutrals.text,
      textMuted: PlezzantNeutrals.textSecondary,
    );
  } else if (dark) {
    c = (
      bg: PlezzantNeutrals.canvas,
      surface: PlezzantNeutrals.surface,
      outline: PlezzantNeutrals.hairline,
      text: PlezzantNeutrals.text,
      textMuted: PlezzantNeutrals.textSecondary,
    );
  } else {
    c = (
      bg: PlezzantNeutrals.lightCanvas,
      surface: PlezzantNeutrals.lightSurface,
      outline: const Color(0x19000000),
      text: PlezzantNeutrals.lightText,
      textMuted: const Color(0x99111116),
    );
  }

  final isDark = dark || oled;
  final clickableCursor = WidgetStateProperty.resolveWith<MouseCursor>(
    (states) => states.contains(WidgetState.disabled) ? MouseCursor.defer : SystemMouseCursors.click,
  );

  final buttonStyle = ButtonStyle(
    mouseCursor: clickableCursor,
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
    textStyle: const WidgetStatePropertyAll(PlezzantType.labelLarge),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(c.text),
    foregroundColor: WidgetStatePropertyAll(isDark ? c.bg : Colors.white),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
  );

  final base = ThemeData(
    platform: platform,
    useMaterial3: true,
    fontFamily: PlezzantType.family,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: c.text,
      onPrimary: isDark ? c.bg : Colors.white,
      secondary: c.text,
      onSecondary: c.bg,
      surface: c.surface,
      onSurface: c.text,
      error: PlezzantPalette.danger.original,
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
    // remove "Material feel"
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    // Explicit mono-derived tile highlights: ListTile's native focus/hover
    // fill is the dpad focus visual inside M3E grouped-list cards.
    focusColor: c.text.withValues(alpha: 0.12),
    hoverColor: c.text.withValues(alpha: 0.05),
    dividerColor: c.outline,
    scaffoldBackgroundColor: c.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.text,
      titleTextStyle: PlezzantType.titleLarge.copyWith(color: c.text),
    ),
    textTheme: PlezzantType.textTheme(text: c.text, muted: c.textMuted),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: .zero,
      shape: const RoundedRectangleBorder(borderRadius: PlezzantRadius.cardAll),
    ),
    inputDecorationTheme: _inputDecorationTheme(c.text, c.textMuted),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    iconButtonTheme: IconButtonThemeData(style: ButtonStyle(mouseCursor: clickableCursor)),
    sliderTheme: SliderThemeData(
      // The mono scheme maps surfaceContainerHighest (the M3 default inactive
      // track) to the same color as surface cards, which makes the inactive
      // track invisible inside grouped-list items.
      inactiveTrackColor: c.text.withValues(alpha: 0.12),
      trackHeight: 16,
      trackGap: 6,
      thumbSize: const WidgetStatePropertyAll(Size(4, 20)),
      thumbShape: const HandleThumbShape(),
      trackShape: const GappedTrackShape(),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
      // ignore: deprecated_member_use — opting into the 2024 slider appearance until the default flips
      year2023: false,
    ),
    dividerTheme: DividerThemeData(space: 0, thickness: 1, color: c.outline),
    // Dialogs and popup menus use the glass panel's solid recipe: a lifted,
    // near-opaque surface with the hairline specular edge and panel radius.
    // Blur adds nothing visible at this opacity and costs frames on TVs.
    dialogTheme: DialogThemeData(
      backgroundColor: Color.alphaBlend(c.text.withValues(alpha: 0.06), c.surface).withValues(alpha: 0.97),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      shape: RoundedRectangleBorder(
        borderRadius: PlezzantRadius.panelAll,
        side: BorderSide(color: c.text.withValues(alpha: 0.10)),
      ),
      titleTextStyle: PlezzantType.headlineSmall.copyWith(color: c.text),
      contentTextStyle: PlezzantType.bodyMedium.copyWith(color: c.textMuted),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Color.alphaBlend(c.text.withValues(alpha: 0.06), c.surface).withValues(alpha: 0.97),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: PlezzantRadius.controlAll,
        side: BorderSide(color: c.text.withValues(alpha: 0.10)),
      ),
      textStyle: PlezzantType.bodyMedium.copyWith(color: c.text),
    ),
    // Not `dense`: Flutter hard-codes dense rows to 13/12 px text, below the
    // Plezzant 14 px floor. Compact visual density keeps rows tight instead.
    listTileTheme: ListTileThemeData(
      dense: false,
      visualDensity: VisualDensity.compact,
      titleTextStyle: PlezzantType.listTitle.copyWith(color: c.text),
      subtitleTextStyle: PlezzantType.bodySmall.copyWith(color: c.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: c.text,
      textColor: c.text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(PlezzantType.labelSmall.copyWith(color: c.textMuted)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(opacity: active ? 1 : 0.6, size: 22, color: c.text);
      }),
    ),
    // Floating snackbars auto-offset above the Scaffold's bottom NavigationBar,
    // so they don't cover it on mobile. Background color tracks the theme to
    // avoid jarring brightness on HDR playback / dark mode.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surface,
      contentTextStyle: PlezzantType.bodyMedium.copyWith(color: c.text),
      actionTextColor: c.text,
      elevation: 6,
      shape: const RoundedRectangleBorder(borderRadius: PlezzantRadius.controlAll),
      insetPadding: const EdgeInsets.all(16),
    ),
  );

  return base.copyWith(
    extensions: [
      MonoTokens(
        radiusSm: PlezzantRadius.sm,
        radiusMd: PlezzantRadius.control,
        radiusLg: PlezzantRadius.panel,
        radiusXs: PlezzantRadius.xs,
        groupGap: 2,
        space: PlezzantSpace.sm,
        fast: PlezzantMotion.focus,
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

/// Brighter fill on focus so input focus is visible inside TV overscan.
InputDecorationTheme _inputDecorationTheme(Color text, Color textMuted) {
  final unfocusedFill = text.withValues(alpha: 0.08);
  final focusedFill = text.withValues(alpha: 0.18);
  const border = OutlineInputBorder(borderRadius: PlezzantRadius.controlAll, borderSide: BorderSide.none);
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
    hintStyle: PlezzantType.bodyMedium.copyWith(color: textMuted),
  );
}
