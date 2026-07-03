import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/transaction.dart';

/// Persistence boundary for inventory products.
///
/// UI and state-management layers should depend on this abstraction so SQLite
/// can later be replaced or complemented by Firebase without changing callers.
abstract class ProductRepository {
  /// Returns all products.
  Future<List<Product>> getProducts();

  /// Returns a single product by id, or null when it does not exist.
  Future<Product?> getProduct(String id);

  /// Persists a new product.
  Future<void> addProduct(Product product);

  /// Persists changes to an existing product.
  Future<void> updateProduct(Product product);

  /// Removes a product by id.
  Future<void> deleteProduct(String id);

  /// Returns all dynamic categories.
  Future<List<String>> getCategories();

  /// Adds a new dynamic category.
  Future<void> addCategory(String category);

  /// Adds starter products only when the product table is empty.
  Future<void> seedDatabaseIfEmpty();

  // --- Transaction & Movement Methods ---

  /// Persists a complete transaction and updates product stock levels.
  Future<void> addTransaction(Transaction transaction);

  /// Returns all transactions ordered by date descending.
  Future<List<Transaction>> getTransactions();

  /// Persists a manual stock adjustment.
  Future<void> addStockMovement(StockMovement movement);

  /// Returns stock history, optionally filtered by product.
  Future<List<StockMovement>> getStockMovements({String? productId});
}
