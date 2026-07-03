import 'package:flutter/material.dart';

/// Animation primitives used across the app. Every screen transition and
/// widget entrance should pull duration/curve/builder from here — never
/// build one-off `Tween`s inline.
class ShadowAnimations {
  ShadowAnimations._();

  // Durations
  static const Duration fast = Duration(milliseconds: 100); // card press
  static const Duration scale = Duration(milliseconds: 200); // scaleIn
  static const Duration medium = Duration(milliseconds: 300); // fadeInUp / slideInRight

  // Curves
  static const Curve enter = Curves.easeOut;
  static const Curve press = Curves.easeInOut;

  // Distances
  static const double fadeInUpOffset = 20.0;
  static const double slideInRightOffset = 30.0;

  // Card press scale target
  static const double cardPressScale = 0.97;

  // StatCard press scale target (scaleIn)
  static const double scaleInFrom = 0.95;

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

  /// Reusable scale-in builder (0.95 → 1.0).
  static Widget scaleIn({
    required Animation<double> animation,
    required Widget child,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        final s = scaleInFrom + (1 - scaleInFrom) * t;
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: s, child: child),
        );
      },
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
