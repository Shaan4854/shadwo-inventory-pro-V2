import 'package:intl/intl.dart';

import 'app_constants.dart';

/// Centralized formatting helpers so no screen builds its own
/// `NumberFormat`/`DateFormat`.
class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );
  static final _compact = NumberFormat.compact();
  static final _dateShort = DateFormat('dd MMM yyyy');
  static final _dateTime = DateFormat('dd MMM yyyy · hh:mm a');
  static final _time = DateFormat('hh:mm a');

  static String currency(num v) => _currency.format(v);
  static String compact(num v) => _compact.format(v);
  static String date(DateTime d) => _dateShort.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
  static String time(DateTime d) => _time.format(d);

  /// Converts a string to Title Case.
  static String titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Capitalizes the first letter of the string.
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Human-readable relative date — "Today", "Yesterday", "3 days ago",
  /// or absolute date for anything older than a week.
  static String relative(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return '$diff days ago';
    if (diff < 0) return 'In the future';
    return date(d);
  }
}
