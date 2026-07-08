import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await SupabaseService.instance.initialize();
  // Initial overlay (dark default); ThemeController refines this once the
  // persisted preference loads and on every theme change.
  SystemChrome.setSystemUIOverlayStyle(
    ShadowTheme.overlayFor(Brightness.dark),
  );
  runApp(const ShadowInventoryApp());
}
