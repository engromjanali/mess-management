import 'package:intl/intl.dart';

/// Formatting helpers shared across the home dashboard widgets.
class DashboardFormatters {
  const DashboardFormatters._();

  static final NumberFormat _money = NumberFormat('#,##0.##', 'en_US');
  static final NumberFormat _count = NumberFormat('#,##0.##', 'en_US');
  static final DateFormat _noticeDate = DateFormat('h:mm a · dd MMM yyyy');

  /// Bangladeshi Taka formatted amount, e.g. `৳12,450`.
  static String taka(double value) => '৳${_money.format(value)}';

  /// Plain numeric count, e.g. `41` or `269.5`.
  static String number(double value) => _count.format(value);

  /// Notice timestamp, e.g. `9:30 AM · 01 Jun 2026`.
  static String noticeTime(DateTime time) => _noticeDate.format(time);
}
