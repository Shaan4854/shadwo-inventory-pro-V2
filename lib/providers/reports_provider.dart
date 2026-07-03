import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../models/stock_movement.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/report_filter.dart';
import 'product_provider.dart';
import 'customer_provider.dart';
import 'supplier_provider.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider({
    required this.productProvider,
    required this.customerProvider,
    required this.supplierProvider,
  });

  final ProductProvider productProvider;
  final CustomerProvider customerProvider;
  final SupplierProvider supplierProvider;

  ReportFilter _filter = ReportFilter(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );

  ReportFilter get filter => _filter;

  void updateFilter(ReportFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  // --- Analytics & Calculations ---

  List<Transaction> get filteredTransactions {
    return productProvider.transactions.where((tx) {
      if (_filter.startDate != null &&
          tx.createdAt.isBefore(_filter.startDate!)) {
        return false;
      }
      if (_filter.endDate != null &&
          tx.createdAt.isAfter(_filter.endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      if (_filter.transactionType != null &&
          tx.type != _filter.transactionType) {
        return false;
      }
      if (_filter.customerId != null && tx.entityId != _filter.customerId) {
        return false;
      }
      if (_filter.supplierId != null && tx.entityId != _filter.supplierId) {
        return false;
      }
      if (_filter.paymentMethod != null &&
          tx.paymentMethod != _filter.paymentMethod) {
        return false;
      }

      if (_filter.productId != null || _filter.category != null) {
        return tx.items.any((item) {
          if (_filter.productId != null && item.productId != _filter.productId) {
            return false;
          }
          if (_filter.category != null) {
            final product = productProvider.products.firstWhere(
              (p) => p.id == item.productId,
              orElse: () => _dummyProduct(),
            );
            if (product.category != _filter.category) return false;
          }
          return true;
        });
      }

      return true;
    }).toList();
  }

  Product _dummyProduct() {
    return Product(
      id: '',
      name: '',
      buyPrice: 0,
      sellPrice: 0,
      stock: 0,
      alertThreshold: 0,
      emoji: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Calculates Net Revenue (Sales - Sales Returns)
  double get totalRevenue {
    double revenue = 0.0;
    for (final tx in filteredTransactions) {
      if (tx.type == TransactionType.sale) {
        revenue += tx.grandTotal;
      } else if (tx.type == TransactionType.salesReturn) {
        revenue -= tx.grandTotal;
      }
    }
    return revenue;
  }

  /// Calculates Net Profit
  double get totalProfit {
    double profit = 0.0;
    for (final tx in filteredTransactions) {
      if (tx.type == TransactionType.sale ||
          tx.type == TransactionType.salesReturn) {
        double txCost = 0;
        for (final item in tx.items) {
          final product = productProvider.products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => _dummyProduct(),
          );
          txCost += product.buyPrice * item.quantity;
        }

        if (tx.type == TransactionType.sale) {
          profit += (tx.grandTotal - txCost);
        } else {
          profit -= (tx.grandTotal - txCost);
        }
      }
    }
    return profit;
  }

  /// Calculates Total Purchases (Purchases - Purchase Returns)
  double get totalPurchases {
    double purchases = 0.0;
    for (final tx in filteredTransactions) {
      if (tx.type == TransactionType.purchase) {
        purchases += tx.grandTotal;
      } else if (tx.type == TransactionType.purchaseReturn) {
        purchases -= tx.grandTotal;
      }
    }
    return purchases;
  }

  Map<String, double> get categoryDistribution {
    final distribution = <String, double>{};
    for (final product in productProvider.products) {
      final category =
          product.category.isEmpty ? 'Uncategorized' : product.category;
      distribution[category] =
          (distribution[category] ?? 0) + (product.stock * product.sellPrice);
    }
    return distribution;
  }

  /// Best Selling Products by Net Quantity (Sold - Returned)
  List<MapEntry<Product, int>> get topSellingProducts {
    final netSales = <String, int>{};
    for (final tx in productProvider.transactions) {
      if (tx.type == TransactionType.sale ||
          tx.type == TransactionType.salesReturn) {
        for (final item in tx.items) {
          final change =
              tx.type == TransactionType.sale ? item.quantity : -item.quantity;
          netSales[item.productId] = (netSales[item.productId] ?? 0) + change;
        }
      }
    }
    final sortedSales = netSales.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSales.take(10).map((e) {
      final product = productProvider.products.firstWhere((p) => p.id == e.key);
      return MapEntry(product, e.value);
    }).toList();
  }

  // --- Chart Data Helpers ---

  List<MapEntry<DateTime, double>> get dailySalesTrend {
    final dailyData = <DateTime, double>{};
    for (final tx in productProvider.transactions) {
      if (tx.type == TransactionType.sale ||
          tx.type == TransactionType.salesReturn) {
        final date =
            DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
        final amount =
            tx.type == TransactionType.sale ? tx.grandTotal : -tx.grandTotal;
        dailyData[date] = (dailyData[date] ?? 0) + amount;
      }
    }
    return dailyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  // --- Specialized Reports ---

  List<Transaction> get salesReport => filteredTransactions
      .where((tx) =>
          tx.type == TransactionType.sale ||
          tx.type == TransactionType.salesReturn,)
      .toList();
  List<Transaction> get purchaseReport => filteredTransactions
      .where((tx) =>
          tx.type == TransactionType.purchase ||
          tx.type == TransactionType.purchaseReturn,)
      .toList();

  List<Product> get lowStockReport => productProvider.products
      .where((p) => productProvider.isLowStock(p))
      .toList();
  List<Product> get outOfStockReport => productProvider.products
      .where((p) => productProvider.isOutOfStock(p))
      .toList();

  double get inventoryValuation => productProvider.products
      .fold(0.0, (sum, p) => sum + (p.stock * p.sellPrice));

  List<MapEntry<Product, double>> get fastMovingProducts {
    return topSellingProducts
        .map((e) => MapEntry(e.key, e.value.toDouble()))
        .toList();
  }

  /// Top Customers by Net Revenue (Total Sales - Total Returns)
  List<MapEntry<Customer, double>> get topCustomers {
    final revenueMap = <String, double>{};
    for (final tx in productProvider.transactions) {
      if (tx.entityId.isNotEmpty &&
          (tx.type == TransactionType.sale ||
              tx.type == TransactionType.salesReturn)) {
        final amount =
            tx.type == TransactionType.sale ? tx.grandTotal : -tx.grandTotal;
        revenueMap[tx.entityId] = (revenueMap[tx.entityId] ?? 0) + amount;
      }
    }
    final sorted = revenueMap.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) {
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Customer(
          id: e.key,
          name: 'Unknown Customer',
          mobile: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return MapEntry(customer, e.value);
    }).toList();
  }

  /// Top Customers by Sales Volume (Net Quantity)
  List<MapEntry<Customer, int>> get topCustomersByVolume {
    final volumeMap = <String, int>{};
    for (final tx in productProvider.transactions) {
      if (tx.entityId.isNotEmpty &&
          (tx.type == TransactionType.sale ||
              tx.type == TransactionType.salesReturn)) {
        int txVolume = 0;
        for (final item in tx.items) {
          txVolume += item.quantity;
        }
        final change = tx.type == TransactionType.sale ? txVolume : -txVolume;
        volumeMap[tx.entityId] = (volumeMap[tx.entityId] ?? 0) + change;
      }
    }
    final sorted = volumeMap.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) {
      final customer = customerProvider.customers.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Customer(
          id: e.key,
          name: 'Unknown Customer',
          mobile: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return MapEntry(customer, e.value);
    }).toList();
  }

  /// Top Suppliers by Purchase Volume (Net Volume)
  List<MapEntry<Supplier, double>> get topSuppliers {
    final volumeMap = <String, double>{};
    for (final tx in productProvider.transactions) {
      if (tx.entityId.isNotEmpty &&
          (tx.type == TransactionType.purchase ||
              tx.type == TransactionType.purchaseReturn)) {
        final amount = tx.type == TransactionType.purchase
            ? tx.grandTotal
            : -tx.grandTotal;
        volumeMap[tx.entityId] = (volumeMap[tx.entityId] ?? 0) + amount;
      }
    }
    final sorted = volumeMap.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) {
      final supplier = supplierProvider.suppliers.firstWhere(
        (s) => s.id == e.key,
        orElse: () => Supplier(
          id: e.key,
          name: 'Unknown Supplier',
          contactPerson: '',
          mobile: '',
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      return MapEntry(supplier, e.value);
    }).toList();
  }

  List<StockMovement> get stockMovementReport {
    return productProvider.movements.where((m) {
      if (_filter.startDate != null &&
          m.createdAt.isBefore(_filter.startDate!)) {
        return false;
      }
      if (_filter.endDate != null &&
          m.createdAt.isAfter(_filter.endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      if (_filter.productId != null && m.productId != _filter.productId) {
        return false;
      }
      return true;
    }).toList();
  }
}
