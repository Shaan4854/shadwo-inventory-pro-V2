import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/transaction_type.dart';
import '../repositories/product_repository.dart';
import '../repositories/variant_repository.dart';
import '../utils/app_constants.dart';
import '../utils/filter_type.dart';
import '../utils/sort_type.dart';

/// State + business logic for the products list. Widgets read via
/// `context.watch<ProductProvider>()` / `.read<>()`; NEVER call
/// `ProductRepository` directly from a widget.
class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductRepository? repository, VariantRepository? variantRepo, Uuid? uuid})
      : _repo = repository ?? ProductRepository(),
        _variantRepo = variantRepo ?? VariantRepository(),
        _uuid = uuid ?? const Uuid();

  final ProductRepository _repo;
  final VariantRepository _variantRepo;
  final Uuid _uuid;

  List<Product> _all = const [];
  final Map<String, Product> _byId = {};
  bool _loading = false;
  Object? _error;
  String _search = '';
  FilterType _filter = FilterType.all;
  SortType _sort = SortType.nameAsc;

  List<Product> get all => List.unmodifiable(_all);
  bool get isLoading => _loading;
  Object? get error => _error;
  String get search => _search;
  FilterType get selectedFilter => _filter;
  SortType get selectedSort => _sort;

  int get totalProducts => _all.where((p) => p.isActive).length;
  int get totalStock =>
      _all.where((p) => p.isActive).fold<int>(0, (sum, p) => sum + p.stock);
  double get inventoryValue =>
      _all.where((p) => p.isActive).fold<double>(0, (sum, p) => sum + p.inventoryValue);
  int get outOfStockCount =>
      _all.where((p) => p.isActive && p.isOutOfStock).length;
  int get lowStockCount =>
      _all.where((p) => p.isActive && p.isLowStock).length;

  List<Product> get outOfStock =>
      List.unmodifiable(_all.where((p) => p.isActive && p.isOutOfStock));
  List<Product> get lowStock =>
      List.unmodifiable(_all.where((p) => p.isActive && p.isLowStock));

  /// Returns products with search + stock-state filter + sort applied.
  /// Only includes active products.
  List<Product> get filteredProducts {
    Iterable<Product> out = _filter == FilterType.archived
        ? _all.where((p) => !p.isActive)
        : _all.where((p) => p.isActive);
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      out = out.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q));
    }
    switch (_filter) {
      case FilterType.all:
        break;
      case FilterType.inStock:
        out = out.where((p) => p.stock > 0);
        break;
      case FilterType.outOfStock:
        out = out.where((p) => p.isOutOfStock);
        break;
      case FilterType.lowStock:
        out = out.where((p) => p.isLowStock);
        break;
      case FilterType.highStock:
        out = out.where((p) => p.stock > p.alertThreshold * 4);
        break;
      case FilterType.archived:
        break;
    }
    final list = out.toList();
    list.sort(_comparator(_sort));
    return list;
  }

  int Function(Product, Product) _comparator(SortType s) {
    switch (s) {
      case SortType.nameAsc:
        return (a, b) => a.name.compareTo(b.name);
      case SortType.nameDesc:
        return (a, b) => b.name.compareTo(a.name);
      case SortType.stockAsc:
        return (a, b) => a.stock.compareTo(b.stock);
      case SortType.stockDesc:
        return (a, b) => b.stock.compareTo(a.stock);
      case SortType.priceAsc:
        return (a, b) => a.sellPrice.compareTo(b.sellPrice);
      case SortType.priceDesc:
        return (a, b) => b.sellPrice.compareTo(a.sellPrice);
      case SortType.marginAsc:
        return (a, b) {
          final ma = a.sellPrice - a.buyPrice;
          final mb = b.sellPrice - b.buyPrice;
          return ma.compareTo(mb);
        };
      case SortType.marginDesc:
        return (a, b) {
          final ma = a.sellPrice - a.buyPrice;
          final mb = b.sellPrice - b.buyPrice;
          return mb.compareTo(ma);
        };
      case SortType.createdAtDesc:
        return (a, b) => b.createdAt.compareTo(a.createdAt);
      case SortType.createdAtAsc:
        return (a, b) => a.createdAt.compareTo(b.createdAt);
    }
  }

  List<Product> recent({int limit = AppConstants.recentItemsCount}) {
    final list = _all.where((p) => p.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  }

  Product? byId(String id) => _byId[id];

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repo.getAll();
      _byId
        ..clear()
        ..addEntries(_all.map((p) => MapEntry(p.id, p)));
    } catch (e) {
      _error = e;
      _all = const [];
      _byId.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    if (q == _search) return;
    _search = q;
    notifyListeners();
  }

  void setFilter(FilterType f) {
    if (f == _filter) return;
    _filter = f;
    notifyListeners();
  }

  void setSort(SortType s) {
    if (s == _sort) return;
    _sort = s;
    notifyListeners();
  }

  Future<Product> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int stock,
    required int alertThreshold,
    required String emoji,
    required String category,
    required String brand,
    required String unit,
    required String sku,
    required String barcode,
    required String notes,
    String imagePath = '',
  }) async {
    final now = DateTime.now();
    final p = Product(
      id: _uuid.v4(),
      name: name,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stock: stock,
      alertThreshold: alertThreshold,
      emoji: emoji,
      category: category,
      brand: brand,
      unit: unit,
      sku: sku,
      barcode: barcode,
      notes: notes,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repo.insert(p);
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
    return p;
  }

  Future<void> updateProduct(Product p) async {
    if (p.stock < 0) {
      throw Exception('Stock cannot be negative');
    }
    try {
      await _repo.update(p);
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repo.delete(id);
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<Product?> findByBarcode(String barcode) async {
    return _repo.findByBarcode(barcode);
  }

  Future<void> restock(String productId, int quantity) async {
    await adjustStock(
      productId: productId,
      delta: quantity,
      reason: 'Barcode restock',
    );
  }

  Future<void> adjustStock({
    required String productId,
    required int delta,
    String reason = '',
  }) async {
    try {
      await _repo.applyStockDelta(
        productId: productId,
        delta: delta,
        type: TransactionType.adjustment,
        reason: reason,
      );
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> duplicateProduct(String id) async {
    try {
      await _repo.duplicate(id, _uuid.v4());
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restoreProduct(String id) async {
    try {
      await _repo.restore(id);
      await load();
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Product>> getArchived() async {
    final all = await _repo.getAll();
    return List.unmodifiable(all.where((p) => !p.isActive));
  }

  Future<String> generateAutoSku() async {
    return _repo.generateNextSku();
  }

  List<ProductVariant> variantsForProduct(String productId) =>
      _variants[productId] ?? const [];

  final Map<String, List<ProductVariant>> _variants = {};

  Future<void> loadVariants(String productId) async {
    try {
      _variants[productId] = await _variantRepo.getForProduct(productId);
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }

  Future<void> addVariant(ProductVariant v) async {
    try {
      await _variantRepo.insert(v);
      await loadVariants(v.productId);
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateVariant(ProductVariant v) async {
    try {
      await _variantRepo.update(v);
      await loadVariants(v.productId);
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteVariant(String id, String productId) async {
    try {
      await _variantRepo.delete(id);
      await loadVariants(productId);
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }
}
