import 'package:equatable/equatable.dart';

import 'transaction_type.dart';

/// Audit-log entry recording every change to a product's stock level.
/// Written from every repository mutation that affects stock (sale,
/// purchase, return, adjustment). Read by the Timeline screen.
class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productEmoji,
    this.productImagePath = '',
    this.transactionId,
    required this.type,
    required this.quantityChange,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String productEmoji;
  final String productImagePath;
  final String? transactionId;
  final TransactionType type;
  final int quantityChange; // signed: negative = out, positive = in
  final String reason;
  final DateTime createdAt;

  bool get isInbound => quantityChange > 0;
  bool get isOutbound => quantityChange < 0;

  Map<String, Object?> toMap() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'product_emoji': productEmoji,
        'product_image_path': productImagePath,
        'transaction_id': transactionId,
        'type': type.toDbString(),
        'quantity_change': quantityChange,
        'reason': reason,
        'created_at': createdAt.toIso8601String(),
      };

  factory StockMovement.fromMap(Map<String, Object?> m) => StockMovement(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        productName: (m['product_name'] as String?) ?? '',
        productEmoji: (m['product_emoji'] as String?) ?? '📦',
        productImagePath: (m['product_image_path'] as String?) ?? '',
        transactionId: m['transaction_id'] as String?,
        type: TransactionType.fromDbString(m['type'] as String),
        quantityChange: (m['quantity_change'] as num).toInt(),
        reason: (m['reason'] as String?) ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productEmoji,
        productImagePath,
        transactionId,
        type,
        quantityChange,
        reason,
        createdAt,
      ];
}
