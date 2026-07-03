/// Inventory sorting options.
enum SortType {
  /// Newest updated products first.
  newest,

  /// Product name A-Z.
  nameAsc,

  /// Product name Z-A.
  nameDesc,

  /// Stock quantity low to high.
  stockAsc,

  /// Stock quantity high to low.
  stockDesc,

  /// Price low to high.
  priceAsc,

  /// Price high to low.
  priceDesc,
}
