import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.currencySymbol = '\$',
    this.currencyPosition = 'left',
    this.dateFormat = 'dd MMM yyyy',
    this.defaultAlertThreshold = 5,
    this.defaultUnit = 'pcs',
    this.paymentMethods = const ['cash', 'card', 'credit'],
    this.createdAt,
    this.updatedAt,
  });

  final String currencySymbol;
  final String currencyPosition;
  final String dateFormat;
  final int defaultAlertThreshold;
  final String defaultUnit;
  final List<String> paymentMethods;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppSettings copyWith({
    String? currencySymbol,
    String? currencyPosition,
    String? dateFormat,
    int? defaultAlertThreshold,
    String? defaultUnit,
    List<String>? paymentMethods,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyPosition: currencyPosition ?? this.currencyPosition,
      dateFormat: dateFormat ?? this.dateFormat,
      defaultAlertThreshold:
          defaultAlertThreshold ?? this.defaultAlertThreshold,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': 1,
        'currency_symbol': currencySymbol,
        'currency_position': currencyPosition,
        'date_format': dateFormat,
        'default_alert_threshold': defaultAlertThreshold,
        'default_unit': defaultUnit,
        'payment_methods': paymentMethods.join(','),
        'created_at': createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updated_at':
            (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  factory AppSettings.fromMap(Map<String, Object?> m) {
    final rawMethods = (m['payment_methods'] as String?) ?? 'cash,card,credit';
    return AppSettings(
      currencySymbol: (m['currency_symbol'] as String?) ?? '\$',
      currencyPosition: (m['currency_position'] as String?) ?? 'left',
      dateFormat: (m['date_format'] as String?) ?? 'dd MMM yyyy',
      defaultAlertThreshold: (m['default_alert_threshold'] as num?)?.toInt() ?? 5,
      defaultUnit: (m['default_unit'] as String?) ?? 'pcs',
      paymentMethods: rawMethods
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'] as String)
          : null,
      updatedAt: m['updated_at'] != null
          ? DateTime.tryParse(m['updated_at'] as String)
          : null,
    );
  }

  static const defaults = AppSettings();

  @override
  List<Object?> get props => [
        currencySymbol,
        currencyPosition,
        dateFormat,
        defaultAlertThreshold,
        defaultUnit,
        paymentMethods,
        createdAt,
        updatedAt,
      ];
}
