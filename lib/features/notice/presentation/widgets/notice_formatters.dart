import 'package:intl/intl.dart';

/// Formatting helpers for the notice screen.
class NoticeFormatters {
  const NoticeFormatters._();

  static final DateFormat _stamp = DateFormat('h:mm a · dd MMM yyyy');

  /// Notice timestamp, e.g. `9:30 AM · 22 Jun 2026`.
  static String time(DateTime value) => _stamp.format(value);
}
