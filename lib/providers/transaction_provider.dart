import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../repositories/customer_repository.dart';
import '../repositories/stock_movement_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/stock_movement.dart';

/// Central provider for transactions, timeline, and stock movements.
/// One provider covers all — sales/purchases/returns share ~90% of
/// their write path; splitting into 5 providers would just duplicate.
class TransactionProvider extends ChangeNotifier {
  TransactionProvider({
    TransactionRepository? txnRepo,
    StockMovementRepository? movementRepo,
    CustomerRepository? customerRepo,
    SupplierRepository? supplierRepo,
    Uuid? uuid,
  })  : _txnRepo = txnRepo ?? TransactionRepository(),
        _moveRepo = movementRepo ?? StockMovementRepository(),
        _customerRepo = customerRepo ?? CustomerRepository(),
        _supplierRepo = supplierRepo ?? SupplierRepository(),
        _uuid = uuid ?? const Uuid();

  final TransactionRepository _txnRepo;
  final StockMovementRepository _moveRepo;
  final CustomerRepository _customerRepo;
  final SupplierRepository _supplierRepo;
  final Uuid _uuid;

  List<Transaction> _all = const [];
  List<StockMovement> _movements = const [];
  bool _loading = false;
  Object? _error;

  List<Transaction> get all => List.unmodifiable(_all);
  List<StockMovement> get movements => List.unmodifiable(_movements);
  bool get isLoading => _loading;
  Object? get error => _error;

  List<Transaction> get sales =>
      _all.where((t) => t.type == TransactionType.sale).toList();
  List<Transaction> get purchases =>
      _all.where((t) => t.type == TransactionType.purchase).toList();

  List<Transaction> recent({int limit = 8}) =>
      _all.take(limit).toList(growable: false);

  double totalRevenue({DateTime? from, DateTime? to}) {
    return _all
        .where((t) => t.type == TransactionType.sale)
        .where((t) => from == null || !t.createdAt.isBefore(from))
        .where((t) => to == null || !t.createdAt.isAfter(to))
        .fold<double>(0, (sum, t) => sum + t.totalAmount);
  }

  double revenueForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return totalRevenue(from: start, to: end);
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _txnRepo.getAll();
      _movements = await _moveRepo.getAll(limit: 200);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Persist a transaction. Applies stock deltas + writes stock_movements
  /// atomically at the repository layer. Also bumps entity outstanding
  /// balance if the transaction was on credit.
  Future<Transaction> createTransaction({
    required TransactionType type,
    required List<_ItemDraft> items,
    required double discount,
    required double taxAmount,
    required String paymentMethod,
    required double paidAmount,
    String entityName = '',
    String entityId = '',
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
          productUnit: it.productUnit,
          quantity: it.quantity,
          priceAtTime: it.priceAtTime,
          discount: it.discount,
          tax: it.tax,
        ),
    ];
    final total = rows.fold<double>(0, (s, r) => s + r.lineSubtotal) -
        discount +
        taxAmount;
    final txn = Transaction(
      id: txnId,
      type: type,
      totalAmount: total,
      discount: discount,
      taxAmount: taxAmount,
      notes: notes,
      paymentMethod: paymentMethod,
      entityName: entityName,
      entityId: entityId,
      paidAmount: paidAmount,
      createdAt: now,
      items: rows,
    );

    final sign = _stockSignFor(type);
    await _txnRepo.create(
      transaction: txn,
      stockDeltaSign: sign,
      movementReason: movementReason,
    );

    // Credit ledger: if partially paid, bump entity outstanding.
    final unpaid = total - paidAmount;
    if (unpaid > 0 && entityId.isNotEmpty) {
      if (type == TransactionType.sale) {
        await _customerRepo.adjustOutstanding(
          customerId: entityId,
          delta: unpaid,
        );
      } else if (type == TransactionType.purchase) {
        await _supplierRepo.adjustOutstanding(
          supplierId: entityId,
          delta: unpaid,
        );
      }
    }

    await load();
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
      case TransactionType.adjustment:
        return 0;
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _txnRepo.delete(id);
    _all = _all.where((t) => t.id != id).toList();
    notifyListeners();
  }
}

/// Lightweight in-memory line-item draft used by the POS/Purchase screens
/// before a Transaction row is persisted. Kept private-ish (leading `_`)
/// so screen code imports it via `TransactionProvider.ItemDraft`-style
/// alias below.
class _ItemDraft {
  const _ItemDraft({
    required this.productId,
    required this.productName,
    required this.productEmoji,
    required this.productUnit,
    required this.quantity,
    required this.priceAtTime,
    this.discount = 0,
    this.tax = 0,
  });

  final String productId;
  final String productName;
  final String productEmoji;
  final String productUnit;
  final int quantity;
  final double priceAtTime;
  final double discount;
  final double tax;
}

typedef TransactionItemDraft = _ItemDraft;

TransactionItemDraft makeItemDraft({
  required String productId,
  required String productName,
  required String productEmoji,
  required String productUnit,
  required int quantity,
  required double priceAtTime,
  double discount = 0,
  double tax = 0,
}) =>
    _ItemDraft(
      productId: productId,
      productName: productName,
      productEmoji: productEmoji,
      productUnit: productUnit,
      quantity: quantity,
      priceAtTime: priceAtTime,
      discount: discount,
      tax: tax,
    );
