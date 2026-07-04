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

  /// Create a transaction and apply all stock movements and entity balance
  /// adjustments in a single atomic DB transaction.
  /// `stockDeltaSign` controls direction:
  ///   +1 for purchase / sales-return (stock IN)
  ///   -1 for sale / purchase-return (stock OUT)
  ///    0 for pure ledger adjustments that do not touch stock
  /// The caller is responsible for passing item quantities as positive
  /// integers; this method applies the sign.
  ///
  /// Throws if stock would become negative (for sales).
  Future<Transaction> create({
    required Transaction transaction,
    required int stockDeltaSign,
    String movementReason = '',
  }) async {
    final db = await _db.database;
    return db.transaction<Transaction>((txn) async {
      // 1. Write the transaction header
      await txn.insert('transactions', transaction.toMap());

      // 2. Process each item (stock movements + item records)
      for (final item in transaction.items) {
        await txn.insert('transaction_items', item.toMap());

        if (stockDeltaSign != 0) {
          final rows = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [item.productId],
            limit: 1,
          );
          if (rows.isEmpty) {
            throw Exception('Product ${item.productId} not found');
          }
          final current = Product.fromMap(rows.first);
          final delta = stockDeltaSign * item.quantity;
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
      }

      // 3. Update entity outstanding balance (if credit involved)
      final unpaid = transaction.totalAmount - transaction.paidAmount;
      // Note: for returns, unpaid might be negative if we're refunding,
      // which should correctly reduce the outstanding balance or increase it
      // depending on the context.
      // Logic:
      // SALE: unpaid > 0 means debt increases for customer.
      // PURCHASE: unpaid > 0 means debt increases for us to supplier.
      // SALE RETURN: we owe customer refund. If we don't pay (paidAmount=0),
      //   unpaid is positive. Does refund reduce customer debt? Yes.
      //   Actually, Sale Return usually REDUCES the customer's balance.
      //   If total is 100 and we paid 0, unpaid = 100.
      //   Wait, a Sale Return should have a "negative" effect on debt.

      if (transaction.entityId.isNotEmpty) {
        double balanceDelta = 0;
        String? table;
        String? idCol;

        switch (transaction.type) {
          case TransactionType.sale:
            table = 'customers';
            idCol = 'id';
            balanceDelta = unpaid;
            break;
          case TransactionType.purchase:
            table = 'suppliers';
            idCol = 'id';
            balanceDelta = unpaid;
            break;
          case TransactionType.salesReturn:
            table = 'customers';
            idCol = 'id';
            // A return reduces what the customer owes.
            // If we refund nothing (paidAmount=0), we owe them.
            // Usually returns are linked to the original sale.
            balanceDelta = -unpaid;
            break;
          case TransactionType.purchaseReturn:
            table = 'suppliers';
            idCol = 'id';
            balanceDelta = -unpaid;
            break;
          case TransactionType.adjustment:
            break;
        }

        if (table != null && balanceDelta != 0) {
          final entityRows = await txn.query(
            table,
            where: '$idCol = ?',
            whereArgs: [transaction.entityId],
            limit: 1,
          );
          if (entityRows.isNotEmpty) {
            final currentBalance =
                (entityRows.first['outstanding_balance'] as num).toDouble();
            await txn.update(
              table,
              {
                'outstanding_balance': currentBalance + balanceDelta,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: '$idCol = ?',
              whereArgs: [transaction.entityId],
            );
          }
        }
      }

      return transaction;
    });
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // 1. Fetch transaction to know what to reverse
      final rows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final items = await _loadItems(db, id);
      final transaction = Transaction.fromMap(rows.first, items: items);

      // 2. Reverse stock changes
      int reversalSign = 0;
      switch (transaction.type) {
        case TransactionType.sale:
          reversalSign = 1; // Put back
          break;
        case TransactionType.purchase:
          reversalSign = -1; // Take out
          break;
        case TransactionType.salesReturn:
          reversalSign = -1; // Take back what was returned
          break;
        case TransactionType.purchaseReturn:
          reversalSign = 1; // Put back what was returned to supplier
          break;
        case TransactionType.adjustment:
          reversalSign = 0;
          break;
      }

      if (reversalSign != 0) {
        for (final item in transaction.items) {
          final pRows = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [item.productId],
            limit: 1,
          );
          if (pRows.isNotEmpty) {
            final current = Product.fromMap(pRows.first);
            final delta = reversalSign * item.quantity;
            final newStock = current.stock + delta;

            if (newStock < 0) {
              throw Exception('Cannot delete transaction: would result in negative stock for ${current.name}');
            }

            await txn.update(
              'products',
              {
                'stock': newStock,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [item.productId],
            );

            // Audit the reversal
            final movement = StockMovement(
              id: _uuid.v4(),
              productId: item.productId,
              productName: current.name,
              productEmoji: current.emoji,
              transactionId: transaction.id,
              type: transaction.type,
              quantityChange: delta,
              reason: 'Transaction Deletion Reversal',
              createdAt: DateTime.now(),
            );
            await txn.insert('stock_movements', movement.toMap());
          }
        }
      }

      // 3. Reverse balance adjustments
      if (transaction.entityId.isNotEmpty) {
        double balanceReversalDelta = 0;
        String? table;
        final unpaid = transaction.totalAmount - transaction.paidAmount;

        switch (transaction.type) {
          case TransactionType.sale:
            table = 'customers';
            balanceReversalDelta = -unpaid;
            break;
          case TransactionType.purchase:
            table = 'suppliers';
            balanceReversalDelta = -unpaid;
            break;
          case TransactionType.salesReturn:
            table = 'customers';
            balanceReversalDelta = unpaid;
            break;
          case TransactionType.purchaseReturn:
            table = 'suppliers';
            balanceReversalDelta = unpaid;
            break;
          case TransactionType.adjustment:
            break;
        }

        if (table != null && balanceReversalDelta != 0) {
          final entityRows = await txn.query(
            table,
            where: 'id = ?',
            whereArgs: [transaction.entityId],
            limit: 1,
          );
          if (entityRows.isNotEmpty) {
            final currentBalance =
                (entityRows.first['outstanding_balance'] as num).toDouble();
            await txn.update(
              table,
              {
                'outstanding_balance': currentBalance + balanceReversalDelta,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [transaction.entityId],
            );
          }
        }
      }

      // 4. Actually delete
      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
      // transaction_items will be deleted via ON DELETE CASCADE
    });
  }
}
