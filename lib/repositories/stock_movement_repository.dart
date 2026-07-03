import '../database/database_helper.dart';
import '../models/stock_movement.dart';

class StockMovementRepository {
  StockMovementRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  Future<List<StockMovement>> getAll({int? limit}) async {
    final db = await _db.database;
    final rows = await db.query(
      'stock_movements',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(StockMovement.fromMap).toList();
  }

  Future<List<StockMovement>> getForProduct(String productId) async {
    final db = await _db.database;
    final rows = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return rows.map(StockMovement.fromMap).toList();
  }
}
