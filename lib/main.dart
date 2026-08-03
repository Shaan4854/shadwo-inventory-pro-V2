import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (layout overflow, render errors, etc.)
  // and display a red error screen instead of a white-screen crash.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.red.shade900,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: ${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  // Catch unhandled async exceptions that escape the framework.
  runZonedGuarded(
    () async {
      try {
        await dotenv.load();
        await SupabaseService.instance.initialize();
      } catch (e) {
        debugPrint('Startup: dotenv/Supabase init failed, running offline: $e');
      }
      // Initial overlay (dark default); ThemeController refines this once the
      // persisted preference loads and on every theme change.
      SystemChrome.setSystemUIOverlayStyle(
        ShadowTheme.overlayFor(Brightness.dark),
      );
      runApp(const ShadowInventoryApp());
    },
    (error, stack) {
      // Log to console; in production this would go to crash reporting.
      debugPrint('Unhandled async error: $error\n$stack');
    },
  );
}
