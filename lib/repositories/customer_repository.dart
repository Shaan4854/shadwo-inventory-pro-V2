import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';

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
  }

  Future<void> update(Customer c) async {
    final db = await _db.database;
    await db.update(
      'customers',
      c.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> adjustOutstanding({
    required String customerId,
    required double delta,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final current = Customer.fromMap(rows.first);
      final updated = current.copyWith(
        outstandingBalance: current.outstandingBalance + delta,
        updatedAt: DateTime.now(),
      );
      await txn.update(
        'customers',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });
  }
}
