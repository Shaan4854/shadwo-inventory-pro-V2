import 'package:flutter/material.dart';

/// Immutable palette holding every themeable color for one brightness.
///
/// Two instances exist: [ShadowPalette.dark] and [ShadowPalette.light].
/// The active one is swapped at runtime by the theme controller through
/// [ShadowColors.palette]. Screens NEVER read a `ShadowPalette` directly —
/// they read the static getters on [ShadowColors], which forward to the
/// currently-active palette. This keeps all 450+ existing call sites
/// (`ShadowColors.foreground`, `ShadowTextStyles.h1`, …) working unchanged
/// while making them theme-aware.
///
/// "Glass / depth" look is achieved WITHOUT `BackdropFilter`/blur (banned
/// for performance on low-end Android). Instead: layered translucent
/// surface gradients, a hairline top highlight border, and soft ambient +
/// colored glow shadows.
@immutable
class ShadowPalette {
  const ShadowPalette({
    required this.brightness,
    required this.background,
    required this.backgroundGradientMid,
    required this.backgroundGradientEnd,
    required this.card,
    required this.cardGradientTop,
    required this.cardGradientBottom,
    required this.glassHighlight,
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
    required this.cardShadow,
    required this.elevatedShadow,
    required this.primaryGlow,
  });

  final Brightness brightness;

  // Backgrounds (3-stop page gradient)
  final Color background;
  final Color backgroundGradientMid;
  final Color backgroundGradientEnd;

  // Surfaces
  final Color card;
  final Color cardGradientTop;
  final Color cardGradientBottom;
  final Color glassHighlight; // hairline top-edge highlight border
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

  // Depth
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedShadow;
  final Color primaryGlow;

  /// Page-level vertical gradient (3 stops for a richer, deeper backdrop).
  LinearGradient get pageBackground => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [background, backgroundGradientMid, backgroundGradientEnd],
        stops: const [0.0, 0.5, 1.0],
      );

  /// Subtle top-lit gradient used to fill glass surfaces (cards, sheets).
  LinearGradient get cardSurface => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cardGradientTop, cardGradientBottom],
      );

  // ------------------------------------------------------------------ dark
  static const ShadowPalette dark = ShadowPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0B1120),
    backgroundGradientMid: Color(0xFF0F172A),
    backgroundGradientEnd: Color(0xFF16223B),
    card: Color(0xFF1B2440),
    cardGradientTop: Color(0xFF222E4F),
    cardGradientBottom: Color(0xFF19223C),
    glassHighlight: Color(0x1AFFFFFF), // white @ 10%
    input: Color(0xFF141D33),
    foreground: Color(0xFFF1F5F9),
    mutedForeground: Color(0xFF94A3B8),
    primary: Color(0xFF60A5FA),
    primaryFg: Color(0xFF0B1120),
    secondary: Color(0xFF374151),
    secondaryFg: Color(0xFFF3F4F6),
    muted: Color(0xFF2A3550),
    accent: Color(0xFF22D3EE),
    destructive: Color(0xFFF87171),
    border: Color(0xFF2C3856),
    accentDefault: Color(0xFF60A5FA),
    accentSage: Color(0xFF34D399),
    accentOlive: Color(0xFF10B981),
    accentTerracotta: Color(0xFFFB923C),
    accentWarning: Color(0xFFFBBF24),
    cardShadow: [
      BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
    elevatedShadow: [
      BoxShadow(color: Color(0x73000000), blurRadius: 28, offset: Offset(0, 14)),
    ],
    primaryGlow: Color(0x5560A5FA), // primary @ ~33%
  );

  // ----------------------------------------------------------------- light
  static const ShadowPalette light = ShadowPalette(
    brightness: Brightness.light,
    background: Color(0xFFFBFCFF),
    backgroundGradientMid: Color(0xFFF1F5FB),
    backgroundGradientEnd: Color(0xFFE7EDF7),
    card: Color(0xFFFFFFFF),
    cardGradientTop: Color(0xFFFFFFFF),
    cardGradientBottom: Color(0xFFF6F9FE),
    glassHighlight: Color(0xE6FFFFFF), // near-white top sheen
    input: Color(0xFFF4F7FC),
    foreground: Color(0xFF0F172A),
    mutedForeground: Color(0xFF64748B),
    primary: Color(0xFF2563EB),
    primaryFg: Color(0xFFFFFFFF),
    secondary: Color(0xFFE2E8F0),
    secondaryFg: Color(0xFF1E293B),
    muted: Color(0xFFEDF1F8),
    accent: Color(0xFF0891B2),
    destructive: Color(0xFFDC2626),
    border: Color(0xFFDCE3EF),
    accentDefault: Color(0xFF2563EB),
    accentSage: Color(0xFF16A34A),
    accentOlive: Color(0xFF059669),
    accentTerracotta: Color(0xFFEA580C),
    accentWarning: Color(0xFFD97706),
    cardShadow: [
      BoxShadow(color: Color(0x14203A66), blurRadius: 18, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
    ],
    elevatedShadow: [
      BoxShadow(color: Color(0x1F1E3A66), blurRadius: 28, offset: Offset(0, 14)),
    ],
    primaryGlow: Color(0x332563EB), // primary @ 20%
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
  static Color get backgroundGradientEnd => palette.backgroundGradientEnd;

  // Surfaces
  static Color get card => palette.card;
  static Color get input => palette.input;
  static Color get glassHighlight => palette.glassHighlight;

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
  static List<BoxShadow> get cardShadow => palette.cardShadow;
  static List<BoxShadow> get elevatedShadow => palette.elevatedShadow;
  static Color get primaryGlow => palette.primaryGlow;

  /// Page-level vertical gradient — swaps with the active palette.
  static LinearGradient get pageBackground => palette.pageBackground;

  /// Subtle top-lit gradient for glass surfaces.
  static LinearGradient get cardSurface => palette.cardSurface;
}
