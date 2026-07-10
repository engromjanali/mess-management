import 'package:intl/intl.dart';

/// Formatting helpers for the cost (Cost) screen.
class CostFormatters {
  const CostFormatters._();

  static final NumberFormat _money = NumberFormat('#,##0.##', 'en_US');
  static final DateFormat _stamp = DateFormat('hh:mm a dd-MM-yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _date = DateFormat('dd/MM/yyyy');

  /// Bangladeshi Taka, e.g. `৳1,500`.
  static String taka(double value) => '৳${_money.format(value)}';

  /// Plain number, e.g. `1,500`.
  static String number(double value) => _money.format(value);

  /// Header stamp, e.g. `04:32 PM 21-08-2025`.
  static String stamp(DateTime value) => _stamp.format(value);

  /// Time only, e.g. `4:31 PM`.
  static String time(DateTime value) => _time.format(value);

  /// Date only, e.g. `21/08/2025`.
  static String date(DateTime value) => _date.format(value);
}
