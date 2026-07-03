import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized typography. System default font (Roboto on Android).
/// Every screen must use one of these — never build a `TextStyle` inline.
class ShadowTextStyles {
  ShadowTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: ShadowColors.foreground,
    height: 1.15,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ShadowColors.foreground,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ShadowColors.foreground,
    height: 1.25,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ShadowColors.foreground,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ShadowColors.foreground,
    height: 1.4,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ShadowColors.mutedForeground,
    height: 1.4,
  );

  /// Uppercase small label — used for stat-card labels, section labels.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: ShadowColors.mutedForeground,
  );

  /// Even smaller uppercase label used inside StatCard (10px, tracking 1.5).
  static const TextStyle statLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: ShadowColors.mutedForeground,
  );

  /// The big number on a StatCard.
  static const TextStyle statValue = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: ShadowColors.foreground,
    height: 1.1,
  );

  /// Sub-label under a StatCard value.
  static const TextStyle statSub = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ShadowColors.mutedForeground,
  );

  /// Label used inside a `ShadowBadge`.
  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ShadowColors.foreground,
    height: 1.0,
  );

  /// Label used inside a `ShadowBadge(compact: true)` — smaller & tighter.
  static const TextStyle badgeCompact = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: ShadowColors.foreground,
    height: 1.0,
  );
}
