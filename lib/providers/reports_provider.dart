import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';

/// Aggregated numbers for the Reports screen. Loads the transactions in a
/// user-selected date range plus the full product catalog, then exposes
/// derived getters. All aggregation is pure — no I/O in getters.
class ReportsProvider extends ChangeNotifier {
  ReportsProvider({
    TransactionRepository? txnRepo,
    ProductRepository? productRepo,
  })  : _txnRepo = txnRepo ?? TransactionRepository(),
        _productRepo = productRepo ?? ProductRepository() {
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    _to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  final TransactionRepository _txnRepo;
  final ProductRepository _productRepo;

  late DateTime _from;
  late DateTime _to;
  List<Transaction> _txns = const [];
  List<Product> _products = const [];
  bool _loading = false;
  Object? _error;

  DateTime get from => _from;
  DateTime get to => _to;
  bool get isLoading => _loading;
  Object? get error => _error;
  List<Transaction> get transactions => List.unmodifiable(_txns);
  List<Product> get products => List.unmodifiable(_products);

  Iterable<Transaction> get _sales =>
      _txns.where((t) => t.type == TransactionType.sale);
  Iterable<Transaction> get _salesReturns =>
      _txns.where((t) => t.type == TransactionType.salesReturn);
  Iterable<Transaction> get _purchases =>
      _txns.where((t) => t.type == TransactionType.purchase);

  double get totalRevenue {
    final gross = _sales.fold<double>(
        0, (s, t) => s + t.totalAmount - t.taxAmount);
    final returns = _salesReturns.fold<double>(
        0, (s, t) => s + t.totalAmount - t.taxAmount);
    return gross - returns;
  }

  double get totalCostOfGoodsSold {
    double cogs = 0;
    for (final sale in _sales) {
      for (final item in sale.items) {
        cogs += (item.costPriceAtTime * item.quantity);
      }
    }
    for (final ret in _salesReturns) {
      for (final item in ret.items) {
        cogs -= (item.costPriceAtTime * item.quantity);
      }
    }
    return cogs;
  }

  /// Total discounts applied on sales (net of returns).
  double get totalDiscounts =>
      _sales.fold<double>(0, (s, t) => s + t.discount) -
      _salesReturns.fold<double>(0, (s, t) => s + t.discount);

  /// Total taxes collected on sales (net of returns).
  double get totalTaxes =>
      _sales.fold<double>(0, (s, t) => s + t.taxAmount) -
      _salesReturns.fold<double>(0, (s, t) => s + t.taxAmount);

  /// Alias for clarity in the Reports screen (COGS is the main expense).
  double get totalExpenses => totalCostOfGoodsSold;

  /// Gross profit = revenue minus cost of goods sold.
  /// Note: discounts and taxes are already baked into `totalAmount` on each
  /// transaction, so they are already reflected in `totalRevenue`.
  double get netProfit => totalRevenue - totalCostOfGoodsSold;
  int get salesCount => _sales.length;
  int get purchaseCount => _purchases.length;

  /// One entry per day in the range, chronologically ordered.
  List<MapEntry<DateTime, double>> get salesByDay {
    final buckets = <DateTime, double>{};
    // Prefill so gaps render as zero on the chart.
    var cursor = DateTime(_from.year, _from.month, _from.day);
    final end = DateTime(_to.year, _to.month, _to.day);
    while (!cursor.isAfter(end)) {
      buckets[cursor] = 0;
      cursor = cursor.add(const Duration(days: 1));
    }
    for (final t in _sales) {
      final d = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      buckets[d] = (buckets[d] ?? 0) + (t.totalAmount - t.taxAmount);
    }
    for (final t in _salesReturns) {
      final d = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      buckets[d] = (buckets[d] ?? 0) - (t.totalAmount - t.taxAmount);
    }
    final list = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  /// Net-of-tax revenue allocated to a single line item. Each line's gross
  /// value is scaled by the transaction's net/total-gross ratio, which
  /// guarantees the per-line breakdown sums exactly to [totalRevenue]
  /// (which is net of tax). Returns 0 when there is no gross value.
  double _lineNetRevenue(Transaction t, TransactionItem it) {
    final gross = t.items.fold<double>(0, (s, i) => s + i.lineSubtotal);
    if (gross <= 0) return 0;
    final net = t.totalAmount - t.taxAmount;
    return it.lineSubtotal * (net / gross);
  }

  /// Top N products by revenue (net of tax, allocated per line so it
  /// reconciles exactly with [totalRevenue]).
  List<MapEntry<String, double>> topProductsByRevenue({int limit = 5}) {
    final byProduct = <String, double>{};
    final names = <String, String>{};
    for (final t in _sales) {
      for (final it in t.items) {
        byProduct[it.productId] =
            (byProduct[it.productId] ?? 0) + _lineNetRevenue(t, it);
        names[it.productId] = it.productName;
      }
    }
    for (final t in _salesReturns) {
      for (final it in t.items) {
        byProduct[it.productId] =
            (byProduct[it.productId] ?? 0) - _lineNetRevenue(t, it);
        names[it.productId] = it.productName;
      }
    }
    final list = byProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list
        .take(limit)
        .map((e) => MapEntry(names[e.key] ?? e.key, e.value))
        .toList();
  }

  /// Category → revenue share for a pie chart.
  /// Each line is allocated net-of-tax so category totals always sum exactly
  /// to [totalRevenue].
  Map<String, double> get revenueByCategory {
    final productsById = {for (final p in _products) p.id: p};
    final byCat = <String, double>{};
    for (final t in _sales) {
      for (final it in t.items) {
        final cat = productsById[it.productId]?.category ?? 'Uncategorized';
        byCat[cat] = (byCat[cat] ?? 0) + _lineNetRevenue(t, it);
      }
    }
    for (final t in _salesReturns) {
      for (final it in t.items) {
        final cat = productsById[it.productId]?.category ?? 'Uncategorized';
        byCat[cat] = (byCat[cat] ?? 0) - _lineNetRevenue(t, it);
      }
    }
    return byCat;
  }

  Future<void> setRange({required DateTime from, required DateTime to}) async {
    _from = from;
    _to = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    await load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _txns = await _txnRepo.getByDateRange(from: _from, to: _to);
      _products = await _productRepo.getAll();
    } catch (e) {
      _error = e;
      _txns = const [];
      _products = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
