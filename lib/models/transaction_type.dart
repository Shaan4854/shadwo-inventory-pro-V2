/// Kind of business transaction. Mirrors React reference `TransactionType`
/// exactly + a value used only in `StockMovement.type` (`adjustment`
/// covers both here, no separate enum needed).
enum TransactionType {
  sale,
  purchase,
  salesReturn,
  purchaseReturn,
  adjustment,
  customerPayment,
  supplierPayment;

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
      case TransactionType.customerPayment:
        return 'customerPayment';
      case TransactionType.supplierPayment:
        return 'supplierPayment';
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
      case 'customerPayment':
        return TransactionType.customerPayment;
      case 'supplierPayment':
        return TransactionType.supplierPayment;
      default:
        return TransactionType.sale;
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
      case TransactionType.customerPayment:
        return 'Payment Received';
      case TransactionType.supplierPayment:
        return 'Payment Made';
    }
  }
}
