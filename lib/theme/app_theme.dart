import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central Material 3 theme builder. The app supports both a dark and a
/// light palette; [build] produces the matching [ThemeData] from a
/// [ShadowPalette]. `MaterialApp.theme` points at the active one, and
/// nothing else should build its own `ThemeData`.
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

  /// Status-bar / nav-bar overlay style for the given [brightness].
  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg =
        isDark ? ShadowPalette.dark.background : ShadowPalette.light.background;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: bg,
      systemNavigationBarIconBrightness: iconBrightness,
    );
  }

  /// Builds the Material theme for a given palette.
  static ThemeData build(ShadowPalette p) {
    final isDark = p.brightness == Brightness.dark;
    final colorScheme = (isDark
            ? const ColorScheme.dark()
            : const ColorScheme.light())
        .copyWith(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.primaryFg,
      secondary: p.secondary,
      onSecondary: p.secondaryFg,
      tertiary: p.accent,
      onTertiary: p.primaryFg,
      error: p.destructive,
      onError: Colors.white,
      surface: p.card,
      onSurface: p.foreground,
      surfaceContainerHighest: p.muted,
      outline: p.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
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
            bodyColor: p.foreground,
            displayColor: p.foreground,
          ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 0.5,
        space: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.input,
        hintStyle: ShadowTextStyles.bodyMuted,
        errorStyle: TextStyle(color: p.destructive, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: p.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: p.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: p.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: p.destructive, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.primaryFg,
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
          foregroundColor: p.foreground,
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
          foregroundColor: p.foreground,
          side: BorderSide(color: p.border),
          textStyle: ShadowTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.primaryFg,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle: ShadowTextStyles.body,
        actionTextColor: p.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: ShadowTextStyles.h4,
        contentTextStyle: ShadowTextStyles.body,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.muted,
        selectedColor: p.primary,
        labelStyle: ShadowTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: ShadowTextStyles.body.copyWith(
          color: p.primaryFg,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
      ),
    );
  }

  /// Convenience builders.
  static ThemeData dark() => build(ShadowPalette.dark);
  static ThemeData light() => build(ShadowPalette.light);
}
