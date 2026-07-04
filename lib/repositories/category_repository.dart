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
    await db.transaction((txn) async {
      final rows = await txn.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return;
      final name = rows.first['name'] as String;

      final products = await txn.query('products', where: 'category = ?', whereArgs: [name], limit: 1);
      if (products.isNotEmpty) {
        throw Exception('Cannot delete category: it is currently assigned to one or more products.');
      }
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }
}
