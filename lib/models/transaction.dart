import 'package:equatable/equatable.dart';

import 'transaction_item.dart';
import 'transaction_type.dart';

/// Business transaction (sale, purchase, return, adjustment). Items are
/// loaded eagerly by the repository — `items` is `const []` for
/// row-only-fetched transactions.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.type,
    required this.totalAmount,
    required this.discount,
    required this.taxAmount,
    required this.notes,
    required this.paymentMethod,
    required this.entityName,
    required this.entityId,
    required this.paidAmount,
    this.originalTransactionId,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final TransactionType type;
  final double totalAmount;
  final double discount;
  final double taxAmount;
  final String notes;
  final String paymentMethod;
  final String entityName;
  final String entityId;
  final double paidAmount;
  final String? originalTransactionId;
  final DateTime createdAt;
  final List<TransactionItem> items;

  double get balance => totalAmount - paidAmount;
  bool get isFullyPaid => paidAmount >= totalAmount;

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? totalAmount,
    double? discount,
    double? taxAmount,
    String? notes,
    String? paymentMethod,
    String? entityName,
    String? entityId,
    double? paidAmount,
    String? originalTransactionId,
    DateTime? createdAt,
    List<TransactionItem>? items,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      taxAmount: taxAmount ?? this.taxAmount,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      entityName: entityName ?? this.entityName,
      entityId: entityId ?? this.entityId,
      paidAmount: paidAmount ?? this.paidAmount,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.toDbString(),
        'total_amount': totalAmount,
        'discount': discount,
        'tax_amount': taxAmount,
        'notes': notes,
        'payment_method': paymentMethod,
        'entity_name': entityName,
        'entity_id': entityId,
        'paid_amount': paidAmount,
        'original_transaction_id': originalTransactionId,
        'created_at': createdAt.toIso8601String(),
      };

  factory Transaction.fromMap(
    Map<String, Object?> m, {
    List<TransactionItem> items = const [],
  }) {
    return Transaction(
      id: m['id'] as String,
      type: TransactionType.fromDbString(m['type'] as String),
      totalAmount: (m['total_amount'] as num).toDouble(),
      discount: ((m['discount'] as num?) ?? 0).toDouble(),
      taxAmount: ((m['tax_amount'] as num?) ?? 0).toDouble(),
      notes: (m['notes'] as String?) ?? '',
      paymentMethod: (m['payment_method'] as String?) ?? 'cash',
      entityName: (m['entity_name'] as String?) ?? '',
      entityId: (m['entity_id'] as String?) ?? '',
      paidAmount: ((m['paid_amount'] as num?) ?? 0).toDouble(),
      originalTransactionId: m['original_transaction_id'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      items: items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        totalAmount,
        discount,
        taxAmount,
        notes,
        paymentMethod,
        entityName,
        entityId,
        paidAmount,
        originalTransactionId,
        createdAt,
        items,
      ];
}
