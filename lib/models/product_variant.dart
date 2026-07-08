import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  const ProductVariant({
    required this.id,
    required this.productId,
    this.name = '',
    this.sku = '',
    this.buyPrice = 0,
    this.sellPrice = 0,
    this.stock = 0,
    this.alertThreshold = 5,
    this.attributes = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String productId;
  final String name;
  final String sku;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final int alertThreshold;
  final Map<String, String> attributes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= alertThreshold;

  ProductVariant copyWith({
    String? id,
    String? productId,
    String? name,
    String? sku,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    int? alertThreshold,
    Map<String, String>? attributes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'product_id': productId,
        'name': name,
        'sku': sku,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'stock': stock,
        'alert_threshold': alertThreshold,
        'attributes': encodeAttributes(attributes),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ProductVariant.fromMap(Map<String, Object?> m) => ProductVariant(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        name: (m['name'] as String?) ?? '',
        sku: (m['sku'] as String?) ?? '',
        buyPrice: (m['buy_price'] as num?)?.toDouble() ?? 0,
        sellPrice: (m['sell_price'] as num?)?.toDouble() ?? 0,
        stock: (m['stock'] as num?)?.toInt() ?? 0,
        alertThreshold: (m['alert_threshold'] as num?)?.toInt() ?? 5,
        attributes: decodeAttributes(m['attributes'] as String?),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  static String encodeAttributes(Map<String, String> attrs) {
    return attrs.entries.map((e) => '${e.key}:${e.value}').join(';');
  }

  static Map<String, String> decodeAttributes(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final map = <String, String>{};
    for (final pair in raw.split(';')) {
      final parts = pair.split(':');
      if (parts.length >= 2) {
        map[parts[0]] = parts.sublist(1).join(':');
      }
    }
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        name,
        sku,
        buyPrice,
        sellPrice,
        stock,
        alertThreshold,
        attributes,
        createdAt,
        updatedAt,
      ];
}
