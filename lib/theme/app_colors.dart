import 'package:flutter/material.dart';

/// Immutable palette holding every themeable color for one brightness.
///
/// Two instances exist: [ShadowPalette.dark] and [ShadowPalette.light].
/// The active one is swapped at runtime by the theme controller through
/// [ShadowColors.palette]. Screens NEVER read a `ShadowPalette` directly —
/// they read the static getters on [ShadowColors], which forward to the
/// currently-active palette.
///
/// Design language: "Civic" — flat surfaces, restrained color, no gradients,
/// no glass effects, no glow shadows. Clean borders and typographic hierarchy.
@immutable
class ShadowPalette {
  const ShadowPalette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.input,
    required this.foreground,
    required this.mutedForeground,
    required this.primary,
    required this.primaryFg,
    required this.secondary,
    required this.secondaryFg,
    required this.muted,
    required this.accent,
    required this.destructive,
    required this.border,
    required this.accentDefault,
    required this.accentSage,
    required this.accentOlive,
    required this.accentTerracotta,
    required this.accentWarning,
    required this.elevatedShadow,
  });

  final Brightness brightness;

  // Backgrounds
  final Color background;

  // Surfaces
  final Color card;
  final Color input;

  // Text
  final Color foreground;
  final Color mutedForeground;

  // Brand
  final Color primary;
  final Color primaryFg;

  // Supporting
  final Color secondary;
  final Color secondaryFg;
  final Color muted;
  final Color accent;
  final Color destructive;

  // Borders
  final Color border;

  // Stat-card accents
  final Color accentDefault;
  final Color accentSage;
  final Color accentOlive;
  final Color accentTerracotta;
  final Color accentWarning;

  // Elevation (only used for bottom sheets, dialogs, FAB)
  final List<BoxShadow> elevatedShadow;

  // ------------------------------------------------------------------ dark
  static const ShadowPalette dark = ShadowPalette(
    brightness: Brightness.dark,
    background: Color(0xFF111111),
    card: Color(0xFF1A1A1A),
    input: Color(0xFF222222),
    foreground: Color(0xFFEDEDEF),
    mutedForeground: Color(0xFFA1A1AA),
    primary: Color(0xFF818CF8),
    primaryFg: Color(0xFF111111),
    secondary: Color(0xFF27272A),
    secondaryFg: Color(0xFFEDEDEF),
    muted: Color(0xFF27272A),
    accent: Color(0xFF2DD4BF),
    destructive: Color(0xFFF87171),
    border: Color(0xFF2E2E2E),
    accentDefault: Color(0xFF818CF8),
    accentSage: Color(0xFF2DD4BF),
    accentOlive: Color(0xFF34D399),
    accentTerracotta: Color(0xFFFB923C),
    accentWarning: Color(0xFFFBBF24),
    elevatedShadow: [
      BoxShadow(color: Color(0x3D000000), blurRadius: 24, offset: Offset(0, 4)),
    ],
  );

  // ----------------------------------------------------------------- light
  static const ShadowPalette light = ShadowPalette(
    brightness: Brightness.light,
    background: Color(0xFFFAFAF8),
    card: Color(0xFFFFFFFF),
    input: Color(0xFFF4F4F5),
    foreground: Color(0xFF18181B),
    mutedForeground: Color(0xFF71717A),
    primary: Color(0xFF4F46E5),
    primaryFg: Color(0xFFFFFFFF),
    secondary: Color(0xFFF4F4F5),
    secondaryFg: Color(0xFF18181B),
    muted: Color(0xFFF4F4F5),
    accent: Color(0xFF0D9488),
    destructive: Color(0xFFDC2626),
    border: Color(0xFFE4E4E7),
    accentDefault: Color(0xFF4F46E5),
    accentSage: Color(0xFF0D9488),
    accentOlive: Color(0xFF059669),
    accentTerracotta: Color(0xFFEA580C),
    accentWarning: Color(0xFFD97706),
    elevatedShadow: [
      BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 4)),
    ],
  );
}

/// Static accessor over the currently-active [ShadowPalette].
///
/// Every screen pulls colors from these getters — no hex literals anywhere
/// else in the codebase. The active palette is swapped at runtime via
/// [palette]; because these are getters (not `const` fields), the values
/// update the moment the palette changes and the widget tree rebuilds.
class ShadowColors {
  ShadowColors._();

  /// The active palette. Set by the theme controller on theme change.
  static ShadowPalette palette = ShadowPalette.dark;

  static Brightness get brightness => palette.brightness;
  static bool get isDark => palette.brightness == Brightness.dark;

  // Backgrounds
  static Color get background => palette.background;

  // Surfaces
  static Color get card => palette.card;
  static Color get input => palette.input;

  // Text
  static Color get foreground => palette.foreground;
  static Color get mutedForeground => palette.mutedForeground;

  // Brand
  static Color get primary => palette.primary;
  static Color get primaryFg => palette.primaryFg;

  // Supporting
  static Color get secondary => palette.secondary;
  static Color get secondaryFg => palette.secondaryFg;
  static Color get muted => palette.muted;
  static Color get accent => palette.accent;
  static Color get destructive => palette.destructive;

  // Borders
  static Color get border => palette.border;

  // Stat-card left-border accents
  static Color get accentDefault => palette.accentDefault;
  static Color get accentSage => palette.accentSage;
  static Color get accentOlive => palette.accentOlive;
  static Color get accentTerracotta => palette.accentTerracotta;
  static Color get accentWarning => palette.accentWarning;

  // Depth tokens
  static List<BoxShadow> get elevatedShadow => palette.elevatedShadow;
}
