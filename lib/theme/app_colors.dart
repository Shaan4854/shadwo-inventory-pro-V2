import 'package:flutter/material.dart';

/// Dark-theme palette derived 1:1 from the React `x` reference project's
/// `.dark { }` CSS variables. Every screen must pull colors from this class —
/// no hex literals anywhere else in the codebase.
class ShadowColors {
  ShadowColors._();

  // Backgrounds
  static const Color background = Color(0xFF0F172A);
  static const Color backgroundGradientEnd = Color(0xFF1A2332);
  static const Color card = Color(0xFF1E2139);
  static const Color input = Color(0xFF1E2139);

  // Text
  static const Color foreground = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF9CA3AF);

  // Brand
  static const Color primary = Color(0xFF60A5FA);
  static const Color primaryFg = Color(0xFF0F172A);

  // Supporting
  static const Color secondary = Color(0xFF374151);
  static const Color secondaryFg = Color(0xFFF3F4F6);
  static const Color muted = Color(0xFF2D3748);
  static const Color accent = Color(0xFF22D3EE); // cyan
  static const Color destructive = Color(0xFFF87171); // red

  // Borders
  static const Color border = Color(0xFF2D3748);

  // Stat-card left-border accents
  static const Color accentDefault = Color(0xFF60A5FA); // blue
  static const Color accentSage = Color(0xFF22C55E); // green
  static const Color accentOlive = Color(0xFF10B981); // emerald
  static const Color accentTerracotta = Color(0xFFF97316); // orange
  static const Color accentWarning = Color(0xFFF59E0B); // amber

  /// Page-level vertical gradient — spec: `#0F172A` → `#1A2332`.
  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundGradientEnd],
  );
}
