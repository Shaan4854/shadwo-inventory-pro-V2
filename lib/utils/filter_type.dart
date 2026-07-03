/// Inventory filters supported by the product state layer.
enum FilterType {
  /// Show every product.
  all,

  /// Show products with stock greater than zero.
  inStock,

  /// Show products with no stock.
  outOfStock,

  /// Show products below their own alert threshold.
  lowStock,

  /// Show products with stock at or above the high-stock threshold.
  highStock,
}
