import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/transaction.dart';
import '../utils/seed_data.dart';
import 'product_repository.dart';

/// SQLite-backed implementation of [ProductRepository].
class SQLiteProductRepository implements ProductRepository {
  /// Creates a repository backed by [databaseHelper].
  SQLiteProductRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<Product>> getProducts() async {
    return _databaseHelper.getProducts();
  }

  @override
  Future<Product?> getProduct(String id) async {
    return _databaseHelper.getProduct(id);
  }

  @override
  Future<void> addProduct(Product product) async {
    await _databaseHelper.insertProduct(product);
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _databaseHelper.updateProduct(product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _databaseHelper.deleteProduct(id);
  }

  @override
  Future<List<String>> getCategories() async {
    return _databaseHelper.getCategories();
  }

  @override
  Future<void> addCategory(String category) async {
    await _databaseHelper.insertCategory(category);
  }

  @override
  Future<void> seedDatabaseIfEmpty() async {
    final int productCount = await _databaseHelper.countProducts();
    if (productCount > 0) {
      return;
    }

    final List<Product> initialProducts = SeedData.initialProducts();
    await _databaseHelper.insertProducts(initialProducts);

    // Seed categories from initial products
    final Set<String> categories = initialProducts
        .map((Product p) => p.category)
        .where((String c) => c.isNotEmpty)
        .toSet();
    for (final String category in categories) {
      await _databaseHelper.insertCategory(category);
    }
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await _databaseHelper.insertTransaction(transaction);
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    return _databaseHelper.getTransactions();
  }

  @override
  Future<void> addStockMovement(StockMovement movement) async {
    await _databaseHelper.insertStockMovement(movement);
  }

  @override
  Future<List<StockMovement>> getStockMovements({String? productId}) async {
    return _databaseHelper.getStockMovements(productId: productId);
  }
}
