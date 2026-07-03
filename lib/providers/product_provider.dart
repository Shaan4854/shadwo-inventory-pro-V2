import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../models/stock_movement.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../utils/app_constants.dart';
import '../utils/filter_type.dart';
import '../utils/sort_type.dart';

/// Owns inventory application state and coordinates product persistence.
class ProductProvider extends ChangeNotifier {
  /// Creates a provider backed by a product repository abstraction.
  ProductProvider({
    required ProductRepository productRepository,
  }) : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final List<Product> _products = <Product>[];
  final List<String> _categories = <String>[];
  final List<Transaction> _transactions = <Transaction>[];
  final List<StockMovement> _movements = <StockMovement>[];

  FilterType _selectedFilter = FilterType.all;
  SortType _selectedSort = SortType.newest;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _alertMessage;

  // --- Cached computed values ---
  bool _cacheValid = false;
  int _cachedTotalStock = 0;
  double _cachedTotalBuyValue = 0.0;
  double _cachedTotalSellValue = 0.0;
  double _cachedTodayProfit = 0.0;
  int _cachedOutOfStockCount = 0;
  int _cachedLowStockCount = 0;

  /// All products currently loaded from persistence.
  UnmodifiableListView<Product> get products {
    return UnmodifiableListView<Product>(_products);
  }

  /// All dynamic categories loaded from persistence.
  UnmodifiableListView<String> get categories {
    return UnmodifiableListView<String>(_categories);
  }

  /// All transactions loaded from persistence.
  UnmodifiableListView<Transaction> get transactions {
    return UnmodifiableListView<Transaction>(_transactions);
  }

  /// All stock movements loaded from persistence.
  UnmodifiableListView<StockMovement> get movements {
    return UnmodifiableListView<StockMovement>(_movements);
  }

  /// Products after applying the current search query, selected filter, and sort.
  List<Product> get filteredProducts {
    Iterable<Product> visibleProducts = _products;

    if (_searchQuery.isNotEmpty) {
      visibleProducts = visibleProducts.where(_matchesSearch);
    }

    visibleProducts = visibleProducts.where(_matchesFilter);

    final List<Product> sortedList = visibleProducts.toList();
    _applySort(sortedList);

    return List<Product>.unmodifiable(sortedList);
  }

  /// Current inventory filter.
  FilterType get selectedFilter => _selectedFilter;

  /// Current inventory sort.
  SortType get selectedSort => _selectedSort;

  /// Current search text.
  String get searchQuery => _searchQuery;

  /// True while an async repository operation is running.
  bool get isLoading => _isLoading;

  /// Last recoverable error message, if any.
  String? get errorMessage => _errorMessage;

  /// Last user-facing alert message, if any.
  String? get alertMessage => _alertMessage;

  /// Total number of products.
  int get totalItems => _products.length;

  /// Total current stock quantity across all products.
  int get totalStock {
    _ensureCacheValid();
    return _cachedTotalStock;
  }

  /// Total current purchase value of stock.
  double get totalBuyValue {
    _ensureCacheValid();
    return _cachedTotalBuyValue;
  }

  /// Total current selling value of stock.
  double get totalSellValue {
    _ensureCacheValid();
    return _cachedTotalSellValue;
  }

  /// Total projected profit for current stock.
  double get totalProfit => totalSellValue - totalBuyValue;

  /// Total profit from transactions today.
  double get todayProfit {
    _ensureCacheValid();
    return _cachedTodayProfit;
  }

  void _ensureCacheValid() {
    if (_cacheValid) {
      return;
    }

    int totalStock = 0;
    double totalBuyValue = 0.0;
    double totalSellValue = 0.0;
    int outOfStockCount = 0;
    int lowStockCount = 0;

    for (final product in _products) {
      totalStock += product.stock;
      totalBuyValue += product.buyPrice * product.stock;
      totalSellValue += product.sellPrice * product.stock;
      if (product.stock == 0) {
        outOfStockCount++;
      }
      if (_isLowStock(product)) {
        lowStockCount++;
      }
    }

    _cachedTotalStock = totalStock;
    _cachedTotalBuyValue = totalBuyValue;
    _cachedTotalSellValue = totalSellValue;
    _cachedOutOfStockCount = outOfStockCount;
    _cachedLowStockCount = lowStockCount;

    // Compute today's profit
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double todayProfit = 0.0;

    for (final tx in _transactions) {
      if (!tx.createdAt.isAfter(today)) {
        continue;
      }
      if (tx.type != TransactionType.sale &&
          tx.type != TransactionType.salesReturn) {
        continue;
      }

      double txProfit = 0;
      for (final item in tx.items) {
        Product? product;
        for (final p in _products) {
          if (p.id == item.productId) {
            product = p;
            break;
          }
        }
        if (product != null) {
          txProfit += (item.priceAtTime - product.buyPrice) * item.quantity;
        }
      }
      if (tx.type == TransactionType.salesReturn) {
        todayProfit -= (txProfit - tx.discount);
      } else {
        todayProfit += (txProfit - tx.discount);
      }
    }

    _cachedTodayProfit = todayProfit;
    _cacheValid = true;
  }

  void _invalidateCache() {
    _cacheValid = false;
  }

  /// Number of products with zero stock.
  int get outOfStockCount {
    _ensureCacheValid();
    return _cachedOutOfStockCount;
  }

  /// Number of products below their own low-stock alert threshold.
  int get lowStockCount {
    _ensureCacheValid();
    return _cachedLowStockCount;
  }

  /// Returns the unit profit for a product.
  double unitProfit(Product product) {
    return product.sellPrice - product.buyPrice;
  }

  /// Returns true when a product has zero stock.
  bool isOutOfStock(Product product) {
    return product.stock == 0;
  }

  /// Returns true when a product is below its own alert threshold.
  bool isLowStock(Product product) {
    return _isLowStock(product);
  }

  /// Loads products, categories, and transactions from the repository.
  Future<void> loadAllData() async {
    _setLoading(true);
    _clearErrorSilently();

    try {
      await _productRepository.seedDatabaseIfEmpty();

      final results = await Future.wait([
        _productRepository.getProducts(),
        _productRepository.getCategories(),
        _productRepository.getTransactions(),
        _productRepository.getStockMovements(),
      ]);

      _replaceProducts(results[0] as List<Product>);

      _categories
        ..clear()
        ..addAll(results[1] as List<String>);

      _transactions
        ..clear()
        ..addAll(results[2] as List<Transaction>);

      _movements
        ..clear()
        ..addAll(results[3] as List<StockMovement>);

      _invalidateCache();
    } catch (error) {
      _setError('Unable to load inventory data.');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads products and categories from the repository.
  Future<void> loadProducts() async {
    await loadAllData();
  }

  /// Computes the stock quantity change for a transaction item based on type.
  int _quantityChangeFor(TransactionType type, int quantity) {
    return switch (type) {
      TransactionType.purchase || TransactionType.salesReturn => quantity,
      TransactionType.sale || TransactionType.purchaseReturn => -quantity,
      TransactionType.adjustment => quantity,
    };
  }

  /// Adds a transaction and applies targeted local state updates.
  Future<void> addTransaction(Transaction transaction) async {
    _clearErrorSilently();

    try {
      await _productRepository.addTransaction(transaction);

      // Update product stock levels locally based on transaction items
      for (final item in transaction.items) {
        final int quantityChange =
            _quantityChangeFor(transaction.type, item.quantity);
        final int index = _products.indexWhere((p) => p.id == item.productId);
        if (index != -1) {
          _products[index] = _products[index].copyWith(
            stock: _products[index].stock + quantityChange,
            updatedAt: transaction.createdAt,
          );
        }
      }

      // Prepend the new transaction
      _transactions.insert(0, transaction);

      // Create stock movements for the new transaction
      final DateTime now = transaction.createdAt;
      for (final item in transaction.items) {
        final int quantityChange =
            _quantityChangeFor(transaction.type, item.quantity);
        _movements.insert(0, StockMovement(
          id: '${now.microsecondsSinceEpoch}_${item.productId}',
          productId: item.productId,
          transactionId: transaction.id,
          type: transaction.type,
          quantityChange: quantityChange,
          reason: transaction.notes,
          createdAt: now,
          productName: item.productName,
          productEmoji: item.productEmoji,
        ),);
      }

      _invalidateCache();
      _alertMessage = 'Transaction saved successfully.';
      notifyListeners();
    } catch (error) {
      _setError('Unable to save transaction.');
    }
  }

  /// Adds a stock movement and applies targeted local state updates.
  Future<void> addStockMovement(StockMovement movement) async {
    _clearErrorSilently();

    try {
      await _productRepository.addStockMovement(movement);

      // Update product stock locally
      final index = _products.indexWhere((p) => p.id == movement.productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          stock: _products[index].stock + movement.quantityChange,
          updatedAt: movement.createdAt,
        );
      }

      // Prepend movement
      _movements.insert(0, movement);

      _invalidateCache();
      _alertMessage = 'Stock adjusted successfully.';
      notifyListeners();
    } catch (error) {
      _setError('Unable to adjust stock.');
    }
  }

  /// Adds a product and refreshes local state.
  Future<void> addProduct(Product product) async {
    _clearErrorSilently();

    try {
      await _productRepository.addProduct(product);
      _products.insert(0, product);
      _setLowStockAlertIfNeeded(product);

      if (product.category.isNotEmpty &&
          !_categories.contains(product.category)) {
        await _productRepository.addCategory(product.category);
        _categories.add(product.category);
      }

      _invalidateCache();
      notifyListeners();
    } catch (error) {
      _setError('Unable to add product.');
    }
  }

  /// Updates a product and refreshes local state.
  Future<void> updateProduct(Product product) async {
    _clearErrorSilently();

    try {
      final int index = _products.indexWhere(
        (Product item) => item.id == product.id,
      );

      if (index != -1) {
        final Product oldProduct = _products[index];
        if (oldProduct.imagePath != null &&
            oldProduct.imagePath != product.imagePath) {
          await _deleteImageFile(oldProduct.imagePath);
        }
        _products[index] = product;
      } else {
        _products.insert(0, product);
      }

      await _productRepository.updateProduct(product);
      _setLowStockAlertIfNeeded(product);

      if (product.category.isNotEmpty &&
          !_categories.contains(product.category)) {
        await _productRepository.addCategory(product.category);
        _categories.add(product.category);
      }

      _invalidateCache();
      notifyListeners();
    } catch (error) {
      _setError('Unable to update product.');
    }
  }

  /// Deletes a product and refreshes local state.
  Future<void> deleteProduct(String productId) async {
    _clearErrorSilently();

    try {
      final int index = _products.indexWhere(
        (Product product) => product.id == productId,
      );

      if (index != -1) {
        final Product product = _products[index];
        if (product.imagePath != null) {
          await _deleteImageFile(product.imagePath);
        }
        _products.removeAt(index);
      }

      await _productRepository.deleteProduct(productId);
      _invalidateCache();
      notifyListeners();
    } catch (error) {
      _setError('Unable to delete product.');
    }
  }

  /// Returns true if the SKU already exists for another product.
  bool isSkuDuplicate(String sku, String? excludeId) {
    if (sku.isEmpty) {
      return false;
    }
    return _products.any((Product p) => p.sku == sku && p.id != excludeId);
  }

  /// Returns true if the barcode already exists for another product.
  bool isBarcodeDuplicate(String barcode, String? excludeId) {
    if (barcode.isEmpty) {
      return false;
    }
    return _products
        .any((Product p) => p.barcode == barcode && p.id != excludeId);
  }

  Future<void> _deleteImageFile(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }

    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('Error deleting image file: $error');
    }
  }

  /// Updates the case-insensitive product search query.
  void search(String query) {
    final String normalizedQuery = query.trim();
    if (_searchQuery == normalizedQuery) {
      return;
    }

    _searchQuery = normalizedQuery;
    notifyListeners();
  }

  /// Changes the selected inventory filter.
  void setFilter(FilterType filter) {
    if (_selectedFilter == filter) {
      return;
    }

    _selectedFilter = filter;
    notifyListeners();
  }

  /// Changes the selected inventory sort.
  void setSort(SortType sort) {
    if (_selectedSort == sort) {
      return;
    }

    _selectedSort = sort;
    notifyListeners();
  }

  /// Clears the current alert message.
  void clearAlert() {
    if (_alertMessage == null) {
      return;
    }

    _alertMessage = null;
    notifyListeners();
  }

  /// Sets a new alert message and notifies listeners.
  void showAlert(String message) {
    _alertMessage = message;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  bool _matchesSearch(Product product) {
    final String query = _searchQuery.toLowerCase();
    final String name = product.name.toLowerCase();
    final String sku = product.sku.toLowerCase();
    final String barcode = product.barcode.toLowerCase();

    return name.contains(query) ||
        sku.contains(query) ||
        barcode.contains(query);
  }

  bool _matchesFilter(Product product) {
    return switch (_selectedFilter) {
      FilterType.all => true,
      FilterType.inStock => product.stock > 0,
      FilterType.outOfStock => product.stock == 0,
      FilterType.lowStock => _isLowStock(product),
      FilterType.highStock => product.stock >= AppConstants.highStockThreshold,
    };
  }

  void _applySort(List<Product> list) {
    switch (_selectedSort) {
      case SortType.newest:
        list.sort((Product a, Product b) => b.updatedAt.compareTo(a.updatedAt));
      case SortType.nameAsc:
        list.sort((Product a, Product b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),);
      case SortType.nameDesc:
        list.sort((Product a, Product b) =>
            b.name.toLowerCase().compareTo(a.name.toLowerCase()),);
      case SortType.stockAsc:
        list.sort((Product a, Product b) => a.stock.compareTo(b.stock));
      case SortType.stockDesc:
        list.sort((Product a, Product b) => b.stock.compareTo(a.stock));
      case SortType.priceAsc:
        list.sort((Product a, Product b) => a.sellPrice.compareTo(b.sellPrice));
      case SortType.priceDesc:
        list.sort((Product a, Product b) => b.sellPrice.compareTo(a.sellPrice));
    }
  }

  bool _isLowStock(Product product) {
    return product.stock > 0 && product.stock < product.alertThreshold;
  }

  void _setLowStockAlertIfNeeded(Product product) {
    if (!_isLowStock(product)) {
      return;
    }

    _alertMessage = '${product.name} is low - only ${product.stock} left!';
  }

  void _replaceProducts(List<Product> products) {
    _products
      ..clear()
      ..addAll(products);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearErrorSilently() {
    _errorMessage = null;
  }
}
