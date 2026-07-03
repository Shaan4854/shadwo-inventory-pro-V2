/// Stock-state filter used by `ProductProvider`. Category is not
/// modelled here — categories are strings on Product and are filtered
/// display-side in the screen layer (see product_list_screen.dart).
enum FilterType {
  all,
  inStock,
  outOfStock,
  lowStock,
  highStock;

  String get displayLabel {
    switch (this) {
      case FilterType.all:
        return 'All';
      case FilterType.inStock:
        return 'In Stock';
      case FilterType.outOfStock:
        return 'Out of Stock';
      case FilterType.lowStock:
        return 'Low Stock';
      case FilterType.highStock:
        return 'High Stock';
    }
  }
}
