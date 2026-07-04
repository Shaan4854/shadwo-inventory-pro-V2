import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central Material 3 dark theme. The whole app is dark-only; there is no
/// light variant. `MaterialApp.theme` should point here, and nothing else
/// should build its own `ThemeData`.
class ShadowTheme {
  ShadowTheme._();

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 100.0;

  // Spacing tokens
  static const double screenPaddingH = 16.0;
  static const double cardPaddingH = 20.0;
  static const double cardPaddingV = 18.0;
  static const double gapCard = 12.0;
  static const double gapSection = 24.0;

  /// Status-bar / nav-bar overlay style — used by AppShell.
  static const SystemUiOverlayStyle systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: ShadowColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: ShadowColors.primary,
      onPrimary: ShadowColors.primaryFg,
      secondary: ShadowColors.secondary,
      onSecondary: ShadowColors.secondaryFg,
      tertiary: ShadowColors.accent,
      onTertiary: ShadowColors.primaryFg,
      error: ShadowColors.destructive,
      onError: Colors.white,
      surface: ShadowColors.card,
      onSurface: ShadowColors.foreground,
      surfaceContainerHighest: ShadowColors.muted,
      outline: ShadowColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ShadowColors.background,
      canvasColor: ShadowColors.background,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            displayLarge: ShadowTextStyles.h1,
            displayMedium: ShadowTextStyles.h2,
            headlineMedium: ShadowTextStyles.h3,
            titleLarge: ShadowTextStyles.h4,
            bodyMedium: ShadowTextStyles.body,
            bodySmall: ShadowTextStyles.bodyMuted,
            labelSmall: ShadowTextStyles.caption,
          )
          .apply(
            bodyColor: ShadowColors.foreground,
            displayColor: ShadowColors.foreground,
          ),
      cardTheme: const CardThemeData(
        color: ShadowColors.card,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ShadowColors.border,
        thickness: 0.5,
        space: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShadowColors.input,
        hintStyle: ShadowTextStyles.bodyMuted,
        errorStyle: const TextStyle(
          color: ShadowColors.destructive,
          fontSize: 12,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide:
              const BorderSide(color: ShadowColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide:
              const BorderSide(color: ShadowColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide:
              const BorderSide(color: ShadowColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide:
              const BorderSide(color: ShadowColors.destructive, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShadowColors.primary,
          foregroundColor: ShadowColors.primaryFg,
          textStyle: ShadowTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ShadowColors.foreground,
          textStyle: ShadowTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ShadowColors.foreground,
          side: const BorderSide(color: ShadowColors.border),
          textStyle: ShadowTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ShadowColors.primary,
        foregroundColor: ShadowColors.primaryFg,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ShadowColors.card,
        contentTextStyle: ShadowTextStyles.body,
        actionTextColor: ShadowColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ShadowColors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: ShadowColors.border,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ShadowColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: ShadowTextStyles.h4,
        contentTextStyle: ShadowTextStyles.body,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ShadowColors.muted,
        selectedColor: ShadowColors.primary,
        labelStyle: ShadowTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: ShadowTextStyles.body.copyWith(
          color: ShadowColors.primaryFg,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: ShadowColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ShadowColors.primary,
      ),
    );
  }
}
