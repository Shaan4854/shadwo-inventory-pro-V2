import 'dart:async';

import '../database/database_helper.dart';
import '../models/product_variant.dart';
import '../services/sync_service.dart';

class VariantRepository {
  VariantRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<List<ProductVariant>> getForProduct(String productId) async {
    final db = await _db.database;
    final rows = await db.query(
      'product_variants',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'name ASC',
    );
    return rows.map(ProductVariant.fromMap).toList();
  }

  Future<void> insert(ProductVariant v) async {
    final db = await _db.database;
    await db.insert('product_variants', v.toMap());
    unawaited(SyncService.instance.upsert('product_variants', v.toMap()));
  }

  Future<void> update(ProductVariant v) async {
    final db = await _db.database;
    final updated = v.copyWith(updatedAt: DateTime.now());
    await db.update(
      'product_variants',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [v.id],
    );
    unawaited(SyncService.instance.upsert('product_variants', updated.toMap()));
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('product_variants', where: 'id = ?', whereArgs: [id]);
    unawaited(SyncService.instance.delete('product_variants', id));
  }

  Future<void> deleteForProduct(String productId) async {
    final db = await _db.database;
    await db.delete(
      'product_variants',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }
}
