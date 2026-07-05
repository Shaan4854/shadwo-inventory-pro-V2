import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File-based flag to track whether the first-launch welcome prompt has
/// been shown. Uses a marker file in the app's documents directory via
/// [path_provider] (already a direct dependency — no new packages added).
///
/// Once the user picks "Start Fresh" or "Restore" the flag is written and
/// the prompt never re-appears — even if the DB becomes empty later.
class FirstLaunchHelper {
  FirstLaunchHelper._();

  static Future<bool> isWelcomeShown() async {
    final file = await _flagFile();
    return file.exists();
  }

  static Future<void> markWelcomeShown() async {
    final file = await _flagFile();
    await file.create();
  }

  static Future<File> _flagFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/.welcome_shown');
  }
}
