import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

class BackupService {
  BackupService._();

  static Future<void> backup() async {
    final db = DatabaseHelper.instance;
    final src = await db.getDatabasePath();
    await db.close();
    try {
      final tmp = await getTemporaryDirectory();
      final dest = p.join(tmp.path, 'shadow_inventory_backup.db');
      await File(src).copy(dest);
      await db.database;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(dest)], text: 'Shadow Inventory Backup'),
      );
    } catch (e) {
      await db.database;
      rethrow;
    }
  }

  static Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  static Future<bool> restore(String pickedPath) async {
    final db = DatabaseHelper.instance;
    final picked = File(pickedPath);
    if (!await picked.exists()) return false;

    final destPath = await db.getDatabasePath();
    await db.close();

    try {
      final dest = File(destPath);
      if (await dest.exists()) {
        await dest.delete();
      }
      await picked.copy(destPath);
    } catch (e) {
      await db.database;
      return false;
    }

    await db.reopenFromBackup(destPath);
    return true;
  }
}
