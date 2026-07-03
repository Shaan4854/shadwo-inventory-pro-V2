/// Kind of business transaction. Mirrors React reference `TransactionType`
/// exactly + a value used only in `StockMovement.type` (`adjustment`
/// covers both here, no separate enum needed).
enum TransactionType {
  sale,
  purchase,
  salesReturn,
  purchaseReturn,
  adjustment;

  String toDbString() {
    switch (this) {
      case TransactionType.sale:
        return 'sale';
      case TransactionType.purchase:
        return 'purchase';
      case TransactionType.salesReturn:
        return 'salesReturn';
      case TransactionType.purchaseReturn:
        return 'purchaseReturn';
      case TransactionType.adjustment:
        return 'adjustment';
    }
  }

  static TransactionType fromDbString(String s) {
    switch (s) {
      case 'sale':
        return TransactionType.sale;
      case 'purchase':
        return TransactionType.purchase;
      case 'salesReturn':
        return TransactionType.salesReturn;
      case 'purchaseReturn':
        return TransactionType.purchaseReturn;
      case 'adjustment':
        return TransactionType.adjustment;
      default:
        throw ArgumentError('Unknown TransactionType: $s');
    }
  }

  String get displayLabel {
    switch (this) {
      case TransactionType.sale:
        return 'Sale';
      case TransactionType.purchase:
        return 'Purchase';
      case TransactionType.salesReturn:
        return 'Sales Return';
      case TransactionType.purchaseReturn:
        return 'Purchase Return';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }
}
