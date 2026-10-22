import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Date formatting helpers for the meal screen.
class MealFormatters {
  const MealFormatters._();

  static final DateFormat _full = DateFormat('EEE, dd MMM');
  static final DateFormat _weekday = DateFormat('E');

  /// e.g. `Mon, 03 Jun`.
  static String dayLabel(DateTime date, {String? locale}) => DateFormat(_full.pattern, locale).format(date);

  /// Single weekday letter for the week chart, e.g. `M`.
  static String weekdayInitial(DateTime date, {String? locale}) => DateFormat(_weekday.pattern, locale).format(date).characters.first;

  /// Plain meal count, dropping a trailing `.0`, e.g. `2` or `1.5`.
  static String count(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
}
