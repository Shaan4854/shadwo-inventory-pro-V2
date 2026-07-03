import 'package:equatable/equatable.dart';
import 'transaction_type.dart';

/// Records a single point-in-time change to a product's stock level.
class StockMovement extends Equatable {
  /// Creates a stock movement.
  const StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantityChange,
    required this.createdAt,
    this.transactionId,
    this.reason = '',
    this.productName = '', // Optimization for list views
    this.productEmoji = '📦',
  });

  /// UUID primary key.
  final String id;

  /// Reference to the affected product.
  final String productId;

  /// Optional reference to a transaction.
  final String? transactionId;

  /// Nature of the change.
  final TransactionType type;

  /// How much the stock changed (+ for increase, - for decrease).
  final int quantityChange;

  /// Why the movement happened (mostly for adjustments).
  final String reason;

  /// When the movement occurred.
  final DateTime createdAt;

  /// Denormalized product name for history views.
  final String productName;

  /// Denormalized product emoji for history views.
  final String productEmoji;

  /// Converts this movement into a SQLite-friendly map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'product_id': productId,
      'transaction_id': transactionId,
      'type': type.name,
      'quantity_change': quantityChange,
      'reason': reason,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a movement from a SQLite map.
  factory StockMovement.fromMap(Map<String, Object?> map,
      {String? productName, String? productEmoji,}) {
    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      transactionId: map['transaction_id'] as String?,
      type: TransactionType.values.byName(map['type'] as String),
      quantityChange: map['quantity_change'] as int,
      reason: map['reason'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      productName: productName ?? '',
      productEmoji: productEmoji ?? '📦',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        productId,
        transactionId,
        type,
        quantityChange,
        reason,
        createdAt,
      ];
}
