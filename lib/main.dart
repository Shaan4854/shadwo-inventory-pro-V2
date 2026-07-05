import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initial overlay (dark default); ThemeController refines this once the
  // persisted preference loads and on every theme change.
  SystemChrome.setSystemUIOverlayStyle(
    ShadowTheme.overlayFor(Brightness.dark),
  );
  runApp(const ShadowInventoryApp());
}
