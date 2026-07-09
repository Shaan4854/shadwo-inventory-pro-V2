import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../repositories/stock_movement_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/stock_movement.dart';

/// Central provider for transactions, timeline, and stock movements.
class TransactionProvider extends ChangeNotifier {
  TransactionProvider({
    TransactionRepository? txnRepo,
    StockMovementRepository? movementRepo,
    Uuid? uuid,
  })  : _txnRepo = txnRepo ?? TransactionRepository(),
        _moveRepo = movementRepo ?? StockMovementRepository(),
        _uuid = uuid ?? const Uuid();

  final TransactionRepository _txnRepo;
  final StockMovementRepository _moveRepo;
  final Uuid _uuid;

  List<Transaction> _all = const [];
  Map<String, Transaction> _byId = const {};
  List<StockMovement> _movements = const [];
  bool _loading = false;
  Object? _error;

  List<Transaction> get all => List.unmodifiable(_all);
  List<StockMovement> get movements => List.unmodifiable(_movements);
  bool get isLoading => _loading;
  Object? get error => _error;

  Transaction? byId(String id) => _byId[id];

  List<Transaction> get sales =>
      _all.where((t) => t.type == TransactionType.sale).toList();
  List<Transaction> get purchases =>
      _all.where((t) => t.type == TransactionType.purchase).toList();

  List<Transaction> recent({int limit = 8}) =>
      _all.take(limit).toList(growable: false);

  double totalRevenue({DateTime? from, DateTime? to}) {
    final inRange = _all.where((t) =>
        (from == null || !t.createdAt.isBefore(from)) &&
        (to == null || t.createdAt.isBefore(to)));
    final gross = inRange
        .where((t) => t.type == TransactionType.sale)
        .fold<double>(0, (sum, t) => sum + t.totalAmount - t.taxAmount);
    final returned = inRange
        .where((t) => t.type == TransactionType.salesReturn)
        .fold<double>(0, (sum, t) => sum + t.totalAmount - t.taxAmount);
    return gross - returned;
  }

  double revenueForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return totalRevenue(from: start, to: end);
  }

  Future<void> load({DateTime? from, DateTime? to}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (from != null && to != null) {
        _all = await _txnRepo.getByDateRange(from: from, to: to);
        _movements = await _moveRepo.getByDateRange(from: from, to: to, limit: 200);
      } else {
        _all = await _txnRepo.getAll();
        _movements = await _moveRepo.getAll(limit: 200);
      }
      _byId = {for (final t in _all) t.id: t};
    } catch (e) {
      _error = e;
      _all = const [];
      _byId = const {};
      _movements = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Persist a transaction. Applies stock deltas + writes stock_movements
  /// atomically at the repository layer. Also handles entity balance
  /// adjustments in the same DB transaction.
  Future<Transaction> createTransaction({
    required TransactionType type,
    required List<TransactionItemDraft> items,
    required double discount,
    required double taxAmount,
    required String paymentMethod,
    required double paidAmount,
    String entityName = '',
    String entityId = '',
    String? originalTransactionId,
    String notes = '',
    String movementReason = '',
  }) async {
    final now = DateTime.now();
    final txnId = _uuid.v4();
    final rows = <TransactionItem>[
      for (final it in items)
        TransactionItem(
          id: _uuid.v4(),
          transactionId: txnId,
          productId: it.productId,
          productName: it.productName,
          productEmoji: it.productEmoji,
          productImagePath: it.productImagePath,
          productUnit: it.productUnit,
          quantity: it.quantity,
          priceAtTime: double.parse(it.priceAtTime.toStringAsFixed(2)),
          costPriceAtTime: double.parse(it.costPriceAtTime.toStringAsFixed(2)),
          discount: double.parse(it.discount.toStringAsFixed(2)),
          tax: double.parse(it.tax.toStringAsFixed(2)),
        ),
    ];

    final subtotal = rows.fold<double>(0, (s, r) => s + r.lineSubtotal);
    final total = double.parse(
        (subtotal - discount + taxAmount).toStringAsFixed(2));

    final txn = Transaction(
      id: txnId,
      type: type,
      totalAmount: total,
      discount: double.parse(discount.toStringAsFixed(2)),
      taxAmount: double.parse(taxAmount.toStringAsFixed(2)),
      notes: notes,
      paymentMethod: paymentMethod,
      entityName: entityName,
      entityId: entityId,
      paidAmount: double.parse(paidAmount.toStringAsFixed(2)),
      originalTransactionId: originalTransactionId,
      createdAt: now,
      items: rows,
    );

    try {
      final sign = _stockSignFor(type);
      await _txnRepo.create(
        transaction: txn,
        stockDeltaSign: sign,
        movementReason: movementReason,
      );
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
    return txn;
  }

  int _stockSignFor(TransactionType t) {
    switch (t) {
      case TransactionType.sale:
        return -1;
      case TransactionType.purchase:
        return 1;
      case TransactionType.salesReturn:
        return 1;
      case TransactionType.purchaseReturn:
        return -1;
      case TransactionType.customerPayment:
      case TransactionType.supplierPayment:
      case TransactionType.adjustment:
        return 0;
    }
  }

  Future<Transaction> recordPayment({
    required String entityId,
    required String entityName,
    required double amount,
    required TransactionType type,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final txnId = _uuid.v4();

    final txn = Transaction(
      id: txnId,
      type: type,
      totalAmount: double.parse(amount.toStringAsFixed(2)),
      discount: 0,
      taxAmount: 0,
      notes: notes,
      paymentMethod: 'cash',
      entityName: entityName,
      entityId: entityId,
      paidAmount: double.parse(amount.toStringAsFixed(2)),
      createdAt: now,
    );

    try {
      await _txnRepo.create(
        transaction: txn,
        stockDeltaSign: 0,
        movementReason: type.displayLabel,
      );
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
    return txn;
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _txnRepo.delete(id);
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }
}

/// Lightweight in-memory line-item draft used by screens.
class TransactionItemDraft {
  const TransactionItemDraft({
    required this.productId,
    required this.productName,
    required this.productEmoji,
    this.productImagePath = '',
    required this.productUnit,
    required this.quantity,
    required this.priceAtTime,
    required this.costPriceAtTime,
    this.discount = 0,
    this.tax = 0,
  });

  final String productId;
  final String productName;
  final String productEmoji;
  final String productImagePath;
  final String productUnit;
  final int quantity;
  final double priceAtTime;
  final double costPriceAtTime;
  final double discount;
  final double tax;
}

TransactionItemDraft makeItemDraft({
  required String productId,
  required String productName,
  required String productEmoji,
  String productImagePath = '',
  required String productUnit,
  required int quantity,
  required double priceAtTime,
  required double costPriceAtTime,
  double discount = 0,
  double tax = 0,
}) =>
    TransactionItemDraft(
      productId: productId,
      productName: productName,
      productEmoji: productEmoji,
      productImagePath: productImagePath,
      productUnit: productUnit,
      quantity: quantity,
      priceAtTime: priceAtTime,
      costPriceAtTime: costPriceAtTime,
      discount: discount,
      tax: tax,
    );
