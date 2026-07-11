import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/transaction_type.dart';
import '../services/sync_service.dart';

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

  /// Finds a single active product by barcode. Returns null if no match
  /// or the barcode is empty/whitespace.
  Future<Product?> findByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return null;
    final db = await _db.database;
    final rows = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [trimmed],
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
    unawaited(SyncService.instance.upsert('products', p.toMap()));
  }

  Future<void> update(Product p) async {
    final db = await _db.database;
    if (p.stock < 0) {
      throw Exception('Stock cannot be negative for ${p.name}');
    }
    final updated = p.copyWith(updatedAt: DateTime.now());
    await db.update(
      'products',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    unawaited(SyncService.instance.upsert('products', updated.toMap()));
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    bool wasSoftDelete = false;
    await db.transaction((txn) async {
      // Check for transaction history
      final history = await txn.query(
        'transaction_items',
        where: 'product_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (history.isNotEmpty) {
        wasSoftDelete = true;
        // Soft delete
        await txn.update(
          'products',
          {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        // Hard delete — clean up orphan stock movements
        await txn.delete('stock_movements', where: 'product_id = ?', whereArgs: [id]);
        await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      }
    });
    if (wasSoftDelete) {
      final p = await getById(id);
      if (p != null) {
        unawaited(SyncService.instance.upsert('products', p.toMap()));
      }
    } else {
      unawaited(SyncService.instance.delete('products', id));
    }
  }

  Future<List<Product>> getArchived() async {
    final db = await _db.database;
    final rows = await db.query(
      'products',
      where: 'is_active = 0',
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<void> restore(String id) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final currentStock =
        (rows.first['stock'] as num).toDouble();
    await db.update(
      'products',
      {'is_active': 1, 'stock': currentStock, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    final p = await getById(id);
    if (p != null) {
      unawaited(SyncService.instance.upsert('products', p.toMap()));
    }
  }

  Future<void> duplicate(String id, String newId) async {
    final original = await getById(id);
    if (original == null) throw Exception('Product not found');
    final now = DateTime.now();
    final copy = original.copyWith(
      id: newId,
      name: '${original.name} (Copy)',
      sku: '${original.sku}-COPY',
      barcode: '',
      stock: 0,
      createdAt: now,
      updatedAt: now,
    );
    await insert(copy);
  }

  Future<String> generateNextSku() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(sku, 5) AS INTEGER)) AS max_num FROM products WHERE sku LIKE 'SKU-%'",
    );
    final maxNum = result.first['max_num'] as int? ?? 0;
    return 'SKU-${(maxNum + 1).toString().padLeft(5, '0')}';
  }

  /// Apply a signed stock delta and audit the change. Throws if stock
  /// would become negative.
  Future<Product?> applyStockDelta({
    required String productId,
    required int delta,
    required TransactionType type,
    String? transactionId,
    String reason = '',
  }) async {
    final db = await _db.database;
    Product? result;
    StockMovement? movement;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final current = Product.fromMap(rows.first);
      final newStock = current.stock + delta;

      if (newStock < 0) {
        throw Exception('Insufficient stock for ${current.name}');
      }

      final updated = current.copyWith(
        stock: newStock,
        updatedAt: DateTime.now(),
      );
      await txn.update(
        'products',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [productId],
      );
      movement = StockMovement(
        id: _uuid.v4(),
        productId: productId,
        productName: current.name,
        productEmoji: current.emoji,
        productImagePath: current.imagePath,
        transactionId: transactionId,
        type: type,
        quantityChange: delta,
        reason: reason,
        createdAt: DateTime.now(),
      );
      await txn.insert('stock_movements', movement!.toMap());
      result = updated;
    });
    if (result != null) {
      unawaited(SyncService.instance.upsert('products', result!.toMap()));
      if (movement != null) {
        unawaited(SyncService.instance.upsert('stock_movements', movement!.toMap()));
      }
    }
    return result;
  }

  /// Set a product's stock directly without writing a stock movement (used
  /// when the product's stock is derived from the sum of its variant stocks).
  Future<void> setStock(String productId, int stock) async {
    final db = await _db.database;
    await db.update(
      'products',
      {'stock': stock, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
    final p = await getById(productId);
    if (p != null) {
      unawaited(SyncService.instance.upsert('products', p.toMap()));
    }
  }

}
