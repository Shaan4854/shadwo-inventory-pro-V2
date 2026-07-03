import 'package:equatable/equatable.dart';

/// Line item on a Transaction. Denormalized product name/emoji/unit so
/// receipts stay correct if the referenced product is later renamed or
/// deleted.
class TransactionItem extends Equatable {
  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.productEmoji,
    required this.productUnit,
    required this.quantity,
    required this.priceAtTime,
    required this.discount,
    required this.tax,
  });

  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final String productEmoji;
  final String productUnit;
  final int quantity;
  final double priceAtTime;
  final double discount;
  final double tax;

  double get lineSubtotal => quantity * priceAtTime;
  double get lineTotal => lineSubtotal - discount + tax;

  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? productId,
    String? productName,
    String? productEmoji,
    String? productUnit,
    int? quantity,
    double? priceAtTime,
    double? discount,
    double? tax,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productEmoji: productEmoji ?? this.productEmoji,
      productUnit: productUnit ?? this.productUnit,
      quantity: quantity ?? this.quantity,
      priceAtTime: priceAtTime ?? this.priceAtTime,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'transaction_id': transactionId,
        'product_id': productId,
        'product_name': productName,
        'product_emoji': productEmoji,
        'product_unit': productUnit,
        'quantity': quantity,
        'price_at_time': priceAtTime,
        'discount': discount,
        'tax': tax,
      };

  factory TransactionItem.fromMap(Map<String, Object?> m) => TransactionItem(
        id: m['id'] as String,
        transactionId: m['transaction_id'] as String,
        productId: m['product_id'] as String,
        productName: (m['product_name'] as String?) ?? '',
        productEmoji: (m['product_emoji'] as String?) ?? '📦',
        productUnit: (m['product_unit'] as String?) ?? 'pcs',
        quantity: (m['quantity'] as num).toInt(),
        priceAtTime: (m['price_at_time'] as num).toDouble(),
        discount: ((m['discount'] as num?) ?? 0).toDouble(),
        tax: ((m['tax'] as num?) ?? 0).toDouble(),
      );

  @override
  List<Object?> get props => [
        id,
        transactionId,
        productId,
        productName,
        productEmoji,
        productUnit,
        quantity,
        priceAtTime,
        discount,
        tax,
      ];
}
