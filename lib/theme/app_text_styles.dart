import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shadow Inventory Pro v2 typography scale.
///
/// Sizes/weights are ported from the React reference's heading scale.
/// Font family is left as the platform default (Roboto on Android),
/// which is the closest system match to the reference's Geist fallback
/// stack. Always reference [ShadowTextStyles] — never inline a
/// `TextStyle` with a hardcoded size/weight in a screen or widget.
class ShadowTextStyles {
  ShadowTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: ShadowColors.foreground,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ShadowColors.foreground,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ShadowColors.foreground,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ShadowColors.foreground,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ShadowColors.foreground,
  );

  /// Uppercase label style — stat card labels, section labels, badges.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: ShadowColors.mutedForeground,
  );
}
