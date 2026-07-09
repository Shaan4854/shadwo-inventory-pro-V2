import 'dart:async';

import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../services/sync_service.dart';

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
    if (transaction.items.isEmpty) {
      throw Exception('Cannot create transaction with no items');
    }
    final db = await _db.database;
    final List<StockMovement> movements = [];

    final result = await db.transaction<Transaction>((txn) async {
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
          unawaited(SyncService.instance.upsert('products', updated.toMap()));

          final movement = StockMovement(
            id: _uuid.v4(),
            productId: item.productId,
            productName: current.name,
            productEmoji: current.emoji,
            productImagePath: current.imagePath,
            transactionId: transaction.id,
            type: transaction.type,
            quantityChange: delta,
            reason: movementReason.isEmpty
                ? transaction.type.displayLabel
                : movementReason,
            createdAt: DateTime.now(),
          );
          await txn.insert('stock_movements', movement.toMap());
          movements.add(movement);
        }
      }

      // 3. Update entity outstanding balance (if credit involved)
      final unpaid = transaction.totalAmount - transaction.paidAmount;

      if (transaction.entityId.isNotEmpty) {
        double balanceDelta = 0;
        String? table;

        switch (transaction.type) {
          case TransactionType.sale:
            table = 'customers';
            balanceDelta = unpaid;
            break;
          case TransactionType.purchase:
            table = 'suppliers';
            balanceDelta = unpaid;
            break;
          case TransactionType.salesReturn:
            table = 'customers';
            balanceDelta = -unpaid;
            break;
          case TransactionType.purchaseReturn:
            table = 'suppliers';
            balanceDelta = -unpaid;
            break;
          case TransactionType.customerPayment:
            table = 'customers';
            balanceDelta = -transaction.totalAmount;
            break;
          case TransactionType.supplierPayment:
            table = 'suppliers';
            balanceDelta = -transaction.totalAmount;
            break;
          case TransactionType.adjustment:
            break;
        }

        if (table != null && balanceDelta != 0) {
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
                'outstanding_balance': currentBalance + balanceDelta,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [transaction.entityId],
            );
          }
        }
      }

      return transaction;
    });

    unawaited(SyncService.instance.upsert('transactions', result.toMap()));
    for (final item in result.items) {
      unawaited(SyncService.instance.upsert('transaction_items', item.toMap()));
    }
    for (final m in movements) {
      unawaited(SyncService.instance.upsert('stock_movements', m.toMap()));
    }
    return result;
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    final List<String> affectedProductIds = [];
    String? affectedEntityId;
    String? affectedEntityTable;

    await db.transaction((txn) async {
      // 1. Fetch transaction to know what to reverse
      final rows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      
      // Use txn handle to load items inside transaction
      final itemRows = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );
      final items = itemRows.map(TransactionItem.fromMap).toList();
      final transaction = Transaction.fromMap(rows.first, items: items);

      affectedProductIds.addAll(items.map((i) => i.productId));

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
          case TransactionType.customerPayment:
          case TransactionType.supplierPayment:
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
            unawaited(SyncService.instance.upsert('products', updated.toMap()));

            // Record reversal as a new audit entry so the timeline shows the correction
            final movement = StockMovement(
              id: _uuid.v4(),
              productId: item.productId,
              productName: current.name,
              productEmoji: current.emoji,
              productImagePath: current.imagePath,
              transactionId: null,
              type: transaction.type,
              quantityChange: delta,
              reason: 'Transaction deleted',
              createdAt: DateTime.now(),
            );
            await txn.insert('stock_movements', movement.toMap());
            unawaited(SyncService.instance.upsert('stock_movements', movement.toMap()));
          }
        }
      }

      // Clean up original stock movements
      await txn.delete('stock_movements', where: 'transaction_id = ?', whereArgs: [id]);

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
          case TransactionType.customerPayment:
            table = 'customers';
            balanceReversalDelta = transaction.totalAmount;
            break;
          case TransactionType.supplierPayment:
            table = 'suppliers';
            balanceReversalDelta = transaction.totalAmount;
            break;
          case TransactionType.adjustment:
            break;
        }

        if (table != null && balanceReversalDelta != 0) {
          affectedEntityId = transaction.entityId;
          affectedEntityTable = table;
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

    unawaited(SyncService.instance.delete('transactions', id));
    for (final pid in affectedProductIds) {
      final pRows = await _db.database.then((db) => db.query(
        'products',
        where: 'id = ?',
        whereArgs: [pid],
        limit: 1,
      ));
      if (pRows.isNotEmpty) {
        unawaited(SyncService.instance.upsert('products', pRows.first));
      }
    }
    if (affectedEntityId != null && affectedEntityTable != null) {
      final db2 = await _db.database;
      final rows = await db2.query(
        affectedEntityTable!,
        where: 'id = ?',
        whereArgs: [affectedEntityId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        unawaited(SyncService.instance.upsert(
          affectedEntityTable!,
          Map<String, Object?>.from(rows.first),
        ));
      }
    }
  }
}
