/// Sort order used by `ProductProvider`.
enum SortType {
  nameAsc,
  nameDesc,
  stockAsc,
  stockDesc,
  priceAsc,
  priceDesc,
  marginAsc,
  marginDesc,
  createdAtDesc,
  createdAtAsc;

  String get displayLabel {
    switch (this) {
      case SortType.nameAsc:
        return 'Name (A \u2192 Z)';
      case SortType.nameDesc:
        return 'Name (Z \u2192 A)';
      case SortType.stockAsc:
        return 'Stock (Low \u2192 High)';
      case SortType.stockDesc:
        return 'Stock (High \u2192 Low)';
      case SortType.priceAsc:
        return 'Price (Low \u2192 High)';
      case SortType.priceDesc:
        return 'Price (High \u2192 Low)';
      case SortType.marginAsc:
        return 'Margin (Low \u2192 High)';
      case SortType.marginDesc:
        return 'Margin (High \u2192 Low)';
      case SortType.createdAtDesc:
        return 'Newest first';
      case SortType.createdAtAsc:
        return 'Oldest first';
    }
  }
}
