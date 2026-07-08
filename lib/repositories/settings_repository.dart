import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<AppSettings> get() async {
    final db = await _db.database;
    final rows = await db.query('app_settings', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const AppSettings();
    return AppSettings.fromMap(rows.first);
  }

  Future<void> save(AppSettings s) async {
    final db = await _db.database;
    await db.insert(
      'app_settings',
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
