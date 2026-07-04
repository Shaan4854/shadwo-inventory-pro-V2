import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<void> insert(Category c) async {
    final db = await _db.database;
    await db.insert(
      'categories',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
