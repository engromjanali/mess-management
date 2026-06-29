import 'package:intl/intl.dart';

/// Formatting helpers for the deposit screen.
class DepositFormatters {
  const DepositFormatters._();

  static final NumberFormat _money = NumberFormat('#,##0.##', 'en_US');
  static final DateFormat _day = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDay = DateFormat('dd MMM');

  /// Bangladeshi Taka, magnitude only, e.g. `৳1,500`.
  static String taka(double value) => '৳${_money.format(value.abs())}';

  /// Signed Taka with an explicit sign, e.g. `+৳1,500` or `-৳300`.
  static String signedTaka(double value) {
    final sign = value < 0 ? '-' : '+';
    return '$sign৳${_money.format(value.abs())}';
  }

  /// Full date, e.g. `01 Jun 2026`.
  static String date(DateTime value) => _day.format(value);

  /// Compact date, e.g. `01 Jun`.
  static String shortDate(DateTime value) => _shortDay.format(value);

  /// Compact inclusive range, e.g. `01 Jun – 10 Jun`.
  static String rangeLabel(DateTime start, DateTime end) => '${_shortDay.format(start)} – ${_shortDay.format(end)}';
}
