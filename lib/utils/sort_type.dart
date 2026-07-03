/// Sort order used by `ProductProvider`.
enum SortType {
  nameAsc,
  nameDesc,
  stockAsc,
  stockDesc,
  priceAsc,
  priceDesc,
  createdAtDesc,
  createdAtAsc;

  String get displayLabel {
    switch (this) {
      case SortType.nameAsc:
        return 'Name (A → Z)';
      case SortType.nameDesc:
        return 'Name (Z → A)';
      case SortType.stockAsc:
        return 'Stock (Low → High)';
      case SortType.stockDesc:
        return 'Stock (High → Low)';
      case SortType.priceAsc:
        return 'Price (Low → High)';
      case SortType.priceDesc:
        return 'Price (High → Low)';
      case SortType.createdAtDesc:
        return 'Newest first';
      case SortType.createdAtAsc:
        return 'Oldest first';
    }
  }
}
