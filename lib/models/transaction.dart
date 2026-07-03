import 'package:equatable/equatable.dart';
import 'transaction_item.dart';
import 'transaction_type.dart';

/// A bundle of stock movements (Sale, Purchase, Return).
class Transaction extends Equatable {
  /// Creates a transaction.
  const Transaction({
    required this.id,
    required this.type,
    required this.totalAmount,
    required this.createdAt,
    this.items = const <TransactionItem>[],
    this.discount = 0,
    this.taxAmount = 0,
    this.notes = '',
    this.paymentMethod = 'Cash',
    this.entityName = 'Walk-in Customer', // Customer or Supplier
    this.entityId = '',
    this.paidAmount = 0.0,
  });

  /// UUID primary key.
  final String id;

  /// Nature of the transaction.
  final TransactionType type;

  /// Calculated subtotal (before discount and tax).
  final double totalAmount;

  /// Applied global discount.
  final double discount;

  /// Applied global tax.
  final double taxAmount;

  /// Final amount after discount and tax.
  double get grandTotal => totalAmount - discount + taxAmount;

  /// Amount paid at the time of transaction.
  final double paidAmount;

  /// Amount remaining (for credit).
  double get balanceAmount => grandTotal - paidAmount;

  /// Internal notes.
  final String notes;

  /// Cash, UPI, Card, etc.
  final String paymentMethod;

  /// Customer name (for Sales) or Supplier name (for Purchases).
  final String entityName;

  /// Link to Customer or Supplier ID.
  final String entityId;

  /// When the transaction was finalized.
  final DateTime createdAt;

  /// Line items within this transaction.
  final List<TransactionItem> items;

  /// Converts this transaction into a SQLite-friendly map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'total_amount': totalAmount,
      'discount': discount,
      'tax_amount': taxAmount,
      'notes': notes,
      'payment_method': paymentMethod,
      'entity_name': entityName,
      'entity_id': entityId,
      'paid_amount': paidAmount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a transaction from a SQLite map.
  factory Transaction.fromMap(Map<String, Object?> map,
      {List<TransactionItem> items = const <TransactionItem>[],}) {
    return Transaction(
      id: map['id'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      paymentMethod: map['payment_method'] as String? ?? 'Cash',
      entityName: map['entity_name'] as String? ?? 'Walk-in Customer',
      entityId: map['entity_id'] as String? ?? '',
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
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
        createdAt,
        items,
      ];
}
