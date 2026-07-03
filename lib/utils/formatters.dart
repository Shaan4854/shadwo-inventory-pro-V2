import 'package:intl/intl.dart';

import 'app_constants.dart';

/// Pure display-formatting helpers — no business rules, just turning
/// already-computed provider values into display strings.
abstract final class Formatters {
  const Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final NumberFormat _compactNumber = NumberFormat.compact();

  static final DateFormat _shortDate = DateFormat('d MMM, h:mm a');

  /// e.g. "৳12,340".
  static String currency(num value) => _currency.format(value);

  /// e.g. "1.2K" — used where a stat card value needs to stay short.
  static String compact(num value) => _compactNumber.format(value);

  /// e.g. "3 Jul, 2:45 PM".
  static String shortDate(DateTime value) => _shortDate.format(value);
}
