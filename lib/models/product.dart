import 'package:equatable/equatable.dart';

/// A stockable item. Fields mirror the React reference `Product` type
/// (see `x/lib/types.ts`) plus SQLite-friendly types (ISO-8601 strings
/// for dates, doubles for money — no BigDecimal in Dart).
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.alertThreshold,
    required this.emoji,
    required this.category,
    required this.brand,
    required this.unit,
    required this.sku,
    required this.barcode,
    required this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final int alertThreshold;
  final String emoji;
  final String category;
  final String brand;
  final String unit;
  final String sku;
  final String barcode;
  final String notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= alertThreshold;
  double get inventoryValue => stock * buyPrice;
  double get potentialRevenue => stock * sellPrice;

  Product copyWith({
    String? id,
    String? name,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    int? alertThreshold,
    String? emoji,
    String? category,
    String? brand,
    String? unit,
    String? sku,
    String? barcode,
    String? notes,
    bool? isActive,
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
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'alert_threshold': alertThreshold,
        'emoji': emoji,
        'category': category,
        'brand': brand,
        'unit': unit,
        'sku': sku,
        'barcode': barcode,
        'notes': notes,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        buyPrice: (m['buy_price'] as num).toDouble(),
        sellPrice: (m['sell_price'] as num).toDouble(),
        stock: (m['stock'] as num).toInt(),
        alertThreshold: (m['alert_threshold'] as num).toInt(),
        emoji: (m['emoji'] as String?) ?? '📦',
        category: (m['category'] as String?) ?? '',
        brand: (m['brand'] as String?) ?? '',
        unit: (m['unit'] as String?) ?? 'pcs',
        sku: (m['sku'] as String?) ?? '',
        barcode: (m['barcode'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
        isActive: (m['is_active'] as int?) != 0,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        buyPrice,
        sellPrice,
        stock,
        alertThreshold,
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
