import 'package:equatable/equatable.dart';

/// Inventory product persisted by the app.
class Product extends Equatable {
  /// Creates a product.
  const Product({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.alertThreshold,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.category = '',
    this.brand = '',
    this.unit = 'pcs',
    this.sku = '',
    this.barcode = '',
    this.notes = '',
  });

  static const Object _unset = Object();

  /// UUID primary key.
  final String id;

  /// Display name shown in the inventory list.
  final String name;

  /// Unit purchase price.
  final double buyPrice;

  /// Unit selling price.
  final double sellPrice;

  /// Current stock quantity.
  final int stock;

  /// Per-product low-stock alert threshold.
  final int alertThreshold;

  /// Local image file path. Null means the fallback emoji should be used.
  final String? imagePath;

  /// Fallback visual when no image is available.
  final String emoji;

  /// Product category.
  final String category;

  /// Product brand.
  final String brand;

  /// Product unit (e.g., pcs, kg, ml).
  final String unit;

  /// Stock keeping unit.
  final String sku;

  /// Barcode value.
  final String barcode;

  /// Internal notes or description.
  final String notes;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Creates a modified copy while keeping unspecified fields unchanged.
  Product copyWith({
    String? id,
    String? name,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    int? alertThreshold,
    Object? imagePath = _unset,
    String? emoji,
    String? category,
    String? brand,
    String? unit,
    String? sku,
    String? barcode,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      imagePath:
          identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this product into a SQLite-friendly map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
      'alert_threshold': alertThreshold,
      'image_path': imagePath,
      'emoji': emoji,
      'category': category,
      'brand': brand,
      'unit': unit,
      'sku': sku,
      'barcode': barcode,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a product from a SQLite map.
  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      buyPrice: (map['buy_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      stock: map['stock'] as int,
      alertThreshold: map['alert_threshold'] as int,
      imagePath: map['image_path'] as String?,
      emoji: map['emoji'] as String,
      category: map['category'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      unit: map['unit'] as String? ?? 'pcs',
      sku: map['sku'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Converts this product into a JSON-compatible map.
  Map<String, Object?> toJson() => toMap();

  /// Creates a product from a JSON-compatible map.
  factory Product.fromJson(Map<String, Object?> json) {
    return Product.fromMap(json);
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        buyPrice,
        sellPrice,
        stock,
        alertThreshold,
        imagePath,
        emoji,
        category,
        brand,
        unit,
        sku,
        barcode,
        notes,
        createdAt,
        updatedAt,
      ];
}
