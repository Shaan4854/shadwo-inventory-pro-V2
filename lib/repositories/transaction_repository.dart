import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';

/// End-to-end transactional writes: creating a sale/purchase/return
/// atomically writes the transaction row, its items, the product stock
/// deltas, and one stock_movements audit row per item.
class TransactionRepository {
  TransactionRepository({DatabaseHelper? db, Uuid? uuid})
      : _db = db ?? DatabaseHelper.instance,
        _uuid = uuid ?? const Uuid();

  final DatabaseHelper _db;
  final Uuid _uuid;

  Future<List<Transaction>> getAll({int? limit}) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    if (rows.isEmpty) return const [];
    return _hydrate(db, rows);
  }

  Future<List<Transaction>> getByDateRange({
    required DateTime from,
    required DateTime to,
    TransactionType? type,
  }) async {
    final db = await _db.database;
    final whereParts = <String>['created_at >= ?', 'created_at <= ?'];
    final args = <Object?>[
      from.toIso8601String(),
      to.toIso8601String(),
    ];
    if (type != null) {
      whereParts.add('type = ?');
      args.add(type.toDbString());
    }
    final rows = await db.query(
      'transactions',
      where: whereParts.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    if (rows.isEmpty) return const [];
    return _hydrate(db, rows);
  }

  Future<Transaction?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final items = await _loadItems(db, id);
    return Transaction.fromMap(rows.first, items: items);
  }

  Future<List<TransactionItem>> _loadItems(Database db, String txnId) async {
    final rows = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [txnId],
    );
    return rows.map(TransactionItem.fromMap).toList();
  }

  Future<List<Transaction>> _hydrate(
    Database db,
    List<Map<String, Object?>> rows,
  ) async {
    final ids = rows.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final itemRows = await db.query(
      'transaction_items',
      where: 'transaction_id IN ($placeholders)',
      whereArgs: ids,
    );
    final byTxn = <String, List<TransactionItem>>{};
    for (final r in itemRows) {
      final item = TransactionItem.fromMap(r);
      byTxn.putIfAbsent(item.transactionId, () => []).add(item);
    }
    return [
      for (final r in rows)
        Transaction.fromMap(
          r,
          items: byTxn[r['id']] ?? const [],
        ),
    ];
  }

  /// Create a transaction and apply all stock movements in a single DB
  /// transaction. `stockDeltaSign` controls direction:
  ///   +1 for purchase / sales-return (stock IN)
  ///   -1 for sale / purchase-return (stock OUT)
  ///    0 for pure ledger adjustments that do not touch stock
  /// The caller is responsible for passing item quantities as positive
  /// integers; this method applies the sign.
  Future<Transaction> create({
    required Transaction transaction,
    required int stockDeltaSign,
    String movementReason = '',
  }) async {
    final db = await _db.database;
    return db.transaction<Transaction>((txn) async {
      await txn.insert('transactions', transaction.toMap());
      for (final item in transaction.items) {
        await txn.insert('transaction_items', item.toMap());
        if (stockDeltaSign == 0) continue;
        final delta = stockDeltaSign * item.quantity;
        final rows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );
        if (rows.isEmpty) continue;
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
          whereArgs: [item.productId],
        );
        final movement = StockMovement(
          id: _uuid.v4(),
          productId: item.productId,
          productName: current.name,
          productEmoji: current.emoji,
          transactionId: transaction.id,
          type: transaction.type,
          quantityChange: delta,
          reason: movementReason.isEmpty
              ? transaction.type.displayLabel
              : movementReason,
          createdAt: DateTime.now(),
        );
        await txn.insert('stock_movements', movement.toMap());
      }
      return transaction;
    });
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
