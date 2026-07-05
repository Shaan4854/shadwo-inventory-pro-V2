import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized typography. System default font (Roboto on Android).
/// Every screen must use one of these — never build a `TextStyle` inline.
///
/// These are getters (not `const` fields) so their colors follow the
/// active [ShadowColors] palette when light/dark mode is toggled.
class ShadowTextStyles {
  ShadowTextStyles._();

  static TextStyle get h1 => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: ShadowColors.foreground,
        height: 1.15,
      );

  static TextStyle get h2 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ShadowColors.foreground,
        height: 1.2,
      );

  static TextStyle get h3 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ShadowColors.foreground,
        height: 1.25,
      );

  static TextStyle get h4 => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ShadowColors.foreground,
        height: 1.3,
      );

  static TextStyle get body => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ShadowColors.foreground,
        height: 1.4,
      );

  static TextStyle get bodyMuted => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ShadowColors.mutedForeground,
        height: 1.4,
      );

  /// Uppercase small label — used for stat-card labels, section labels.
  static TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: ShadowColors.mutedForeground,
      );

  /// Even smaller uppercase label used inside StatCard (10px, tracking 1.5).
  static TextStyle get statLabel => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: ShadowColors.mutedForeground,
      );

  /// The big number on a StatCard.
  static TextStyle get statValue => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ShadowColors.foreground,
        height: 1.1,
      );

  /// Sub-label under a StatCard value.
  static TextStyle get statSub => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ShadowColors.mutedForeground,
      );

  /// Label used inside a `ShadowBadge`.
  static TextStyle get badge => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ShadowColors.foreground,
        height: 1.0,
      );

  /// Label used inside a `ShadowBadge(compact: true)` — smaller & tighter.
  static TextStyle get badgeCompact => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: ShadowColors.foreground,
        height: 1.0,
      );
}
