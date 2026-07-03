import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/transaction_type.dart';

/// All product read/write goes through here. Providers call these
/// methods — never sqflite directly. Widgets never call these either.
class ProductRepository {
  ProductRepository({DatabaseHelper? db, Uuid? uuid})
      : _db = db ?? DatabaseHelper.instance,
        _uuid = uuid ?? const Uuid();

  final DatabaseHelper _db;
  final Uuid _uuid;

  Future<List<Product>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<void> insert(Product p) async {
    final db = await _db.database;
    await db.insert(
      'products',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Product p) async {
    final db = await _db.database;
    await db.update(
      'products',
      p.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Apply a signed stock delta and audit the change. Used by sale /
  /// purchase / return / adjustment flows.
  Future<Product?> applyStockDelta({
    required String productId,
    required int delta,
    required TransactionType type,
    String? transactionId,
    String reason = '',
  }) async {
    final db = await _db.database;
    return db.transaction<Product?>((txn) async {
      final rows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final current = Product.fromMap(rows.first);
      final newStock = current.stock + delta;
      final updated = current.copyWith(
        stock: newStock < 0 ? 0 : newStock,
        updatedAt: DateTime.now(),
      );
      await txn.update(
        'products',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [productId],
      );
      final movement = StockMovement(
        id: _uuid.v4(),
        productId: productId,
        productName: current.name,
        productEmoji: current.emoji,
        transactionId: transactionId,
        type: type,
        quantityChange: delta,
        reason: reason,
        createdAt: DateTime.now(),
      );
      await txn.insert('stock_movements', movement.toMap());
      return updated;
    });
  }
}
