import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/supplier.dart';

class SupplierRepository {
  SupplierRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<List<Supplier>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('suppliers', orderBy: 'name ASC');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<Supplier?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Supplier.fromMap(rows.first);
  }

  Future<void> insert(Supplier s) async {
    final db = await _db.database;
    await db.insert(
      'suppliers',
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Supplier s) async {
    final db = await _db.database;
    await db.update(
      'suppliers',
      s.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final txns = await txn.query('transactions', where: 'entity_id = ?', whereArgs: [id], limit: 1);
      if (txns.isNotEmpty) {
        throw Exception('Cannot delete supplier: they have an existing purchase history.');
      }
      await txn.delete('suppliers', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> adjustOutstanding({
    required String supplierId,
    required double delta,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'suppliers',
        where: 'id = ?',
        whereArgs: [supplierId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final current = Supplier.fromMap(rows.first);
      final updated = current.copyWith(
        outstandingBalance: current.outstandingBalance + delta,
        updatedAt: DateTime.now(),
      );
      await txn.update(
        'suppliers',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [supplierId],
      );
    });
  }
}
