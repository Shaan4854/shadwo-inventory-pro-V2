import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_colors.dart';
import 'app_theme.dart';

/// User-selectable theme preference.
enum AppThemeMode { light, dark, system }

/// Owns the app-wide light/dark preference and keeps [ShadowColors] pointed
/// at the correct palette.
///
/// Persistence: the single preference is written to a small text file in the
/// app support directory via `path_provider` (already a dependency) — no new
/// packages and no migration on the locked sqflite database.
///
/// "System" mode follows the OS brightness and updates live when the user
/// changes their system theme.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController() {
    WidgetsBinding.instance.addObserver(this);
    _platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _apply();
  }

  static const String _fileName = 'theme_pref.txt';

  AppThemeMode _mode = AppThemeMode.dark;
  Brightness _platformBrightness = Brightness.dark;
  bool _loaded = false;

  AppThemeMode get mode => _mode;
  bool get loaded => _loaded;

  /// Resolves [mode] + OS brightness into the concrete brightness in effect.
  Brightness get effectiveBrightness {
    switch (_mode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return _platformBrightness;
    }
  }

  bool get isDark => effectiveBrightness == Brightness.dark;

  ShadowPalette get palette =>
      isDark ? ShadowPalette.dark : ShadowPalette.light;

  /// The Material theme matching the active palette.
  ThemeData get themeData => ShadowTheme.build(palette);

  /// Points [ShadowColors] at the active palette and syncs system chrome.
  void _apply() {
    ShadowColors.palette = palette;
    SystemChrome.setSystemUIOverlayStyle(
      ShadowTheme.overlayFor(effectiveBrightness),
    );
  }

  /// Loads the persisted preference. Safe to call once at startup; failures
  /// fall back to the default (dark) silently.
  Future<void> load() async {
    try {
      final file = await _prefFile();
      if (await file.exists()) {
        final raw = (await file.readAsString()).trim();
        _mode = _parse(raw) ?? _mode;
      }
    } catch (_) {
      // Ignore — keep default.
    }
    _loaded = true;
    _apply();
    notifyListeners();
  }

  /// Switches the theme preference, persists it, and rebuilds the app.
  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    _apply();
    notifyListeners();
    await _persist();
  }

  /// Convenience: flip between light and dark (used by the header quick
  /// toggle). If currently on "system", flip relative to what's showing.
  Future<void> toggle() async {
    await setMode(isDark ? AppThemeMode.light : AppThemeMode.dark);
  }

  @override
  void didChangePlatformBrightness() {
    _platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_mode == AppThemeMode.system) {
      _apply();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<File> _prefFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<void> _persist() async {
    try {
      final file = await _prefFile();
      await file.writeAsString(_mode.name, flush: true);
    } catch (_) {
      // Non-fatal: preference just won't survive restart.
    }
  }

  static AppThemeMode? _parse(String raw) {
    for (final m in AppThemeMode.values) {
      if (m.name == raw) return m;
    }
    return null;
  }
}
