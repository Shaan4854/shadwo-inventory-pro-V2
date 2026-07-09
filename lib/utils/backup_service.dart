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
    final tmp = await getTemporaryDirectory();
    final dest = p.join(tmp.path, 'shadow_inventory_backup.db');
    await File(src).copy(dest);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(dest)], text: 'Shadow Inventory Backup'),
    );
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
    final tmpPath = '$destPath.restore_tmp';

    try {
      // Copy to temp path first to avoid data loss if copy fails
      await picked.copy(tmpPath);
      // Verify the copy is valid by opening it briefly
      await DatabaseHelper.instance.reopenFromBackup(tmpPath);
      // Swap: close current DB, replace with temp
      final dest = File(destPath);
      if (await dest.exists()) {
        await dest.delete();
      }
      await File(tmpPath).copy(destPath);
      await db.reopenFromBackup(destPath);
      final tmpFile = File(tmpPath);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
      return true;
    } catch (e) {
      // Re-open original if possible
      try {
        await db.database;
      } catch (_) {}
      final tmpFile = File(tmpPath);
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
      return false;
    }
  }
}
