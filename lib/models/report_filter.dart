import 'package:equatable/equatable.dart';
import 'transaction_type.dart';

class ReportFilter extends Equatable {
  const ReportFilter({
    this.startDate,
    this.endDate,
    this.productId,
    this.category,
    this.customerId,
    this.supplierId,
    this.paymentMethod,
    this.transactionType,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? productId;
  final String? category;
  final String? customerId;
  final String? supplierId;
  final String? paymentMethod;
  final TransactionType? transactionType;

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? category,
    String? customerId,
    String? supplierId,
    String? paymentMethod,
    TransactionType? transactionType,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      productId: productId ?? this.productId,
      category: category ?? this.category,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionType: transactionType ?? this.transactionType,
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        productId,
        category,
        customerId,
        supplierId,
        paymentMethod,
        transactionType,
      ];
}
