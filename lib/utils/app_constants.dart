import 'package:flutter/material.dart';

/// Centralized app constants derived from the original Shadow HTML design.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Shadow Inventory Pro';
  static const String shortAppName = 'Shadow';
  static const String appSubtitle = 'Inventory';

  static const String currencySymbol = '৳';
  static const int defaultLowStockAlert = 5;
  static const int highStockThreshold = 20;
  static const int lowStockFilterThreshold = 5;
  static const double maxContentWidth = 430;

  static const List<String> productCategories = <String>[
    'General',
    'Electronics',
    'Accessories',
    'Clothing',
    'Footwear',
    'Home',
    'Other',
  ];

  static const List<String> fallbackEmojis = <String>[
    '📦',
    '🛍️',
    '🎁',
    '⚡',
    '🔌',
    '📱',
    '💻',
    '🎧',
    '👕',
    '👟',
  ];

  static const AppColors colors = AppColors();
  static const AppSpacing spacing = AppSpacing();
  static const AppDurations durations = AppDurations();
  static const AppRadii radii = AppRadii();
}

class AppColors {
  const AppColors();

  final Color background = const Color(0xFF0A0A0F);
  final Color backgroundAlt = const Color(0xFF12121A);
  final Color surface = const Color(0xFF161622);
  final Color surfaceHigh = const Color(0xFF1E1E2E);
  final Color border = const Color(0xFF242435);

  final Color primary = const Color(0xFF6366F1);
  final Color primaryDark = const Color(0xFF4F46E5);
  final Color primaryLight = const Color(0xFF818CF8);

  final Color blue = const Color(0xFF3B82F6);
  final Color red = const Color(0xFFEF4444);
  final Color green = const Color(0xFF10B981);
  final Color yellow = const Color(0xFFF59E0B);
  final Color purple = const Color(0xFF8B5CF6);
  final Color orange = const Color(0xFFF97316);

  final Color textPrimary = const Color(0xFFFFFFFF);
  final Color textSecondary = const Color(0xFF94A3B8);
  final Color textMuted = const Color(0xFF64748B);
  final Color onAccent = Colors.white;
  final Color onDanger = Colors.white;

  final LinearGradient dashboardGradient = const LinearGradient(
    colors: <Color>[Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  const AppSpacing();

  final double xxs = 2;
  final double xs = 4;
  final double sm = 6;
  final double md = 8;
  final double lg = 10;
  final double xl = 12;
  final double xxl = 14;
  final double page = 16;
  final double fabMargin = 18;
  final double bottomListPadding = 90;
}

class AppRadii {
  const AppRadii();

  final double sm = 6;
  final double md = 10;
  final double lg = 12;
  final double xl = 14;
  final double sheet = 22;
  final double pill = 20;
}

class AppDurations {
  const AppDurations();

  final Duration fast = const Duration(milliseconds: 150);
  final Duration normal = const Duration(milliseconds: 250);
  final Duration sheet = const Duration(milliseconds: 320);
  final Duration alert = const Duration(milliseconds: 350);
  final Duration alertVisible = const Duration(milliseconds: 3500);
}
