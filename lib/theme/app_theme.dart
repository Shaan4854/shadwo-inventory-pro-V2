import 'package:flutter/material.dart';

import 'app_animations.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the single [ThemeData] for Shadow Inventory Pro v2.
///
/// The app is dark-only (per the master build prompt) — there is no
/// light theme to switch to. Always read colors/text styles from
/// [ShadowColors]/[ShadowTextStyles]; this class only wires them into
/// the Material 3 theme so built-in widgets (Scaffold, AppBar, etc.)
/// pick up the right defaults.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final ColorScheme colorScheme = const ColorScheme.dark().copyWith(
      surface: ShadowColors.background,
      onSurface: ShadowColors.foreground,
      primary: ShadowColors.primary,
      onPrimary: ShadowColors.primaryFg,
      secondary: ShadowColors.secondary,
      onSecondary: ShadowColors.secondaryFg,
      error: ShadowColors.destructive,
      onError: ShadowColors.primaryFg,
      outline: ShadowColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ShadowColors.background,
      canvasColor: ShadowColors.background,
      cardColor: ShadowColors.card,
      dividerColor: ShadowColors.border,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          for (final TargetPlatform platform in TargetPlatform.values)
            platform: _FadeInUpTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ShadowColors.background,
        foregroundColor: ShadowColors.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: ShadowTextStyles.h3,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ShadowColors.card,
        selectedItemColor: ShadowColors.primary,
        unselectedItemColor: ShadowColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      textTheme: const TextTheme(
        displayLarge: ShadowTextStyles.h1,
        headlineMedium: ShadowTextStyles.h2,
        titleLarge: ShadowTextStyles.h3,
        titleMedium: ShadowTextStyles.h4,
        bodyMedium: ShadowTextStyles.body,
        labelSmall: ShadowTextStyles.caption,
      ),
      fontFamily: 'Roboto',
    );
  }
}

/// Applies [ShadowAnimation.pageTransitionsBuilder] (fadeInUp) as the
/// default transition for every route on every platform, per the master
/// prompt's "All page transitions: fadeInUp" rule.
class _FadeInUpTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ShadowAnimation.pageTransitionsBuilder(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
