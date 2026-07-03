import 'package:flutter/material.dart';

/// Shadow Inventory Pro v2 motion constants + reusable transition helpers.
///
/// Durations/curves are ported from the React reference's motion spec.
/// Screens/widgets should use these helpers instead of hand-rolling
/// `AnimatedContainer`/`PageRouteBuilder` timings.
class ShadowAnimation {
  ShadowAnimation._();

  // Durations
  static const Duration fadeInUp = Duration(milliseconds: 300);
  static const Duration scaleIn = Duration(milliseconds: 200);
  static const Duration slideInRight = Duration(milliseconds: 300);
  static const Duration cardPress = Duration(milliseconds: 100);

  // Curves
  static const Curve fadeInUpCurve = Curves.easeOut;
  static const Curve scaleInCurve = Curves.easeOut;
  static const Curve slideInRightCurve = Curves.easeOut;
  static const Curve cardPressCurve = Curves.easeOut;

  // Offsets / scales
  static const double fadeInUpOffset = 20;
  static const double slideInRightOffset = 30;
  static const double scaleInFrom = 0.95;
  static const double cardPressScale = 0.97;

  /// Wraps [child] with the "fadeInUp" entrance animation: slides up
  /// [fadeInUpOffset] px while fading in. Used for one-shot entrance
  /// animations on cards/sections (not page transitions — see
  /// [pageRouteBuilder] for that).
  static Widget wrapFadeInUp({required Widget child, Duration? delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: fadeInUp,
      curve: fadeInUpCurve,
      builder: (BuildContext context, double t, Widget? c) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, fadeInUpOffset * (1 - t)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  /// Wraps [child] with the "scaleIn" entrance animation: scales from
  /// [scaleInFrom] up to 1.0 while fading in.
  static Widget wrapScaleIn({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: scaleInFrom, end: 1),
      duration: scaleIn,
      curve: scaleInCurve,
      builder: (BuildContext context, double t, Widget? c) {
        return Opacity(
          opacity: (t - scaleInFrom) / (1 - scaleInFrom),
          child: Transform.scale(scale: t, child: c),
        );
      },
      child: child,
    );
  }

  /// Wraps [child] with the "slideInRight" entrance animation: slides in
  /// from [slideInRightOffset] px on the right while fading in.
  static Widget wrapSlideInRight({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: slideInRight,
      curve: slideInRightCurve,
      builder: (BuildContext context, double t, Widget? c) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(slideInRightOffset * (1 - t), 0),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  /// Standard page transition for the whole app: fadeInUp. Pass to
  /// [PageRouteBuilder.transitionsBuilder] when building routes in
  /// `app_routes.dart`.
  static Widget pageTransitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: fadeInUpCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (BuildContext context, Widget? c) {
          return Transform.translate(
            offset: Offset(0, fadeInUpOffset * (1 - curved.value)),
            child: c,
          );
        },
      ),
    );
  }

  /// Route builder that applies [pageTransitionsBuilder] with [fadeInUp]
  /// duration — use for every named/pushed route in the app.
  static PageRouteBuilder<T> fadeInUpRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          page,
      transitionDuration: fadeInUp,
      reverseTransitionDuration: fadeInUp,
      transitionsBuilder: pageTransitionsBuilder,
    );
  }
}
