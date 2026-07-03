import 'package:equatable/equatable.dart';

/// A product within a transaction.
class TransactionItem extends Equatable {
  /// Creates a transaction item.
  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.priceAtTime,
    this.discount = 0.0,
    this.tax = 0.0,
    this.productName = '',
    this.productEmoji = '📦',
    this.productUnit = 'pcs',
  });

  /// UUID primary key.
  final String id;

  /// Parent transaction ID.
  final String transactionId;

  /// Product reference.
  final String productId;

  /// Quantity moved.
  final int quantity;

  /// Price of the item at the time of transaction.
  final double priceAtTime;

  /// Line-level discount.
  final double discount;

  /// Line-level tax.
  final double tax;

  /// Denormalized product name.
  final String productName;

  /// Denormalized product emoji.
  final String productEmoji;

  /// Denormalized product unit.
  final String productUnit;

  /// Total for this line item (Price * Qty - Discount + Tax).
  double get total => (priceAtTime * quantity) - discount + tax;

  /// Converts this item into a SQLite-friendly map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_time': priceAtTime,
      'discount': discount,
      'tax': tax,
    };
  }

  /// Creates an item from a SQLite map.
  factory TransactionItem.fromMap(
    Map<String, Object?> map, {
    String? productName,
    String? productEmoji,
    String? productUnit,
  }) {
    return TransactionItem(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int,
      priceAtTime: (map['price_at_time'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      productName: productName ?? '',
      productEmoji: productEmoji ?? '📦',
      productUnit: productUnit ?? 'pcs',
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[id, transactionId, productId, quantity, priceAtTime, discount, tax];
}
