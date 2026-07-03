/// Types of inventory transactions.
enum TransactionType {
  /// Buying items from a supplier.
  purchase,

  /// Selling items to a customer.
  sale,

  /// Customer returning items.
  salesReturn,

  /// Returning items to a supplier.
  purchaseReturn,

  /// Manual stock correction.
  adjustment,
}
