import 'package:intl/intl.dart';

/// Date formatting helpers for the meal screen.
class MealFormatters {
  const MealFormatters._();

  static final DateFormat _full = DateFormat('EEE, dd MMM');
  static final DateFormat _weekday = DateFormat('E');

  /// e.g. `Mon, 03 Jun`.
  static String dayLabel(DateTime date) => _full.format(date);

  /// Single weekday letter for the week chart, e.g. `M`.
  static String weekdayInitial(DateTime date) =>
      _weekday.format(date).substring(0, 1);

  /// Plain meal count, dropping a trailing `.0`, e.g. `2` or `1.5`.
  static String count(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
}
