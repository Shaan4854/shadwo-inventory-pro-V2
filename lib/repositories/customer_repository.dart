import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../services/sync_service.dart';

class CustomerRepository {
  CustomerRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<List<Customer>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('customers', orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<void> insert(Customer c) async {
    final db = await _db.database;
    await db.insert(
      'customers',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    unawaited(SyncService.instance.upsert('customers', c.toMap()));
  }

  Future<void> update(Customer c) async {
    final db = await _db.database;
    final updated = c.copyWith(updatedAt: DateTime.now());
    await db.update(
      'customers',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
    unawaited(SyncService.instance.upsert('customers', updated.toMap()));
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final txns = await txn.query('transactions', where: 'entity_id = ?', whereArgs: [id], limit: 1);
      if (txns.isNotEmpty) {
        throw Exception('Cannot delete customer: they have an existing transaction history.');
      }
      await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
    });
    unawaited(SyncService.instance.delete('customers', id));
  }
}
