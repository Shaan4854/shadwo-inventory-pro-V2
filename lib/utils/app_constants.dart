/// App-wide magic values. Keep here — no other file should hardcode a
/// currency symbol, DB name, or seed threshold.
class AppConstants {
  AppConstants._();

  static const String appName = 'Shadow Inventory Pro';
  static const String dbName = 'shadow_inventory_v12.db';
  static const int dbVersion = 14;

  /// Default low-stock threshold used on new products until the user sets
  /// something else on the form.
  static const int defaultAlertThreshold = 5;

  /// Default currency symbol. Displayed via `Formatters.currency(...)`.
  static const String currencySymbol = '\$';

  /// Payment methods offered in the POS payment sheet.
  static const List<String> paymentMethods = [
    'cash',
    'card',
    'credit',
  ];

  /// Default unit shown on new products.
  static const String defaultUnit = 'pcs';

  /// Predefined measurement units for the product form picker.
  static const List<String> units = [
    'pcs',
    'kg',
    'g',
    'litre',
    'ml',
    'm',
    'cm',
    'box',
    'pack',
    'dozen',
    'piece',
    'pair',
    'set',
    'roll',
    'bottle',
    'bag',
    'strip',
    'tube',
    'can',
    'jar',
  ];

  /// Dashboard: number of items shown in each "recent" strip.
  static const int recentItemsCount = 8;

  /// Product list: page size for infinite scroll (if used).
  static const int listPageSize = 50;
}
