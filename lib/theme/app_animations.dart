import 'package:flutter/material.dart';

/// Animation primitives used across the app. Every screen transition and
/// widget entrance should pull duration/curve/builder from here — never
/// build one-off `Tween`s inline.
///
/// Design language: "Civic" — spring-based curves, fast durations,
/// opacity-based press feedback (not scale).
class ShadowAnimations {
  ShadowAnimations._();

  // Durations
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration scale = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 220);

  // Curves — spring-inspired for natural feel
  static const Curve enter = Curves.easeOutCubic;
  static const Curve press = Curves.easeInOut;

  // Distances
  static const double fadeInUpOffset = 16.0;
  static const double slideInRightOffset = 24.0;

  // Press feedback — opacity, not scale (avoids AI-generated feel)
  static const double pressOpacity = 0.7;

  // Stagger
  static const Duration staggerBase = Duration(milliseconds: 140);
  static const int staggerStepMs = 30;

  /// Reusable fade-in-up entrance builder — use as the child of an
  /// [AnimatedBuilder] driven by a [AnimationController].
  static Widget fadeInUp({
    required Animation<double> animation,
    required Widget child,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * fadeInUpOffset),
            child: child,
          ),
        );
      },
    );
  }

  /// Reusable slide-in-from-right entrance builder.
  static Widget slideInRight({
    required Animation<double> animation,
    required Widget child,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * slideInRightOffset, 0),
            child: child,
          ),
        );
      },
    );
  }

  /// Reusable scale-in builder (0.96 -> 1.0).
  static Widget scaleIn({
    required Animation<double> animation,
    required Widget child,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        final s = 0.96 + 0.04 * t;
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: s, child: child),
        );
      },
    );
  }

  /// Staggered fade-in-up entrance for list items.
  static Widget staggerItem({
    required int index,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: staggerBase + Duration(milliseconds: index * staggerStepMs),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1.0 - v) * 16.0),
          child: child,
        ),
      ),
    );
  }

  /// PageRoute that applies the fadeInUp transition — use for all push
  /// navigations (detail screens, form sheets pushed as pages).
  static PageRouteBuilder<T> fadeInUpRoute<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: medium,
      reverseTransitionDuration: medium,
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) =>
          fadeInUp(animation: animation, child: child),
    );
  }
}
