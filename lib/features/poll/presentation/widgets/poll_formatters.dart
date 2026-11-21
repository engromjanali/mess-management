import 'package:intl/intl.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

/// Formatting helpers for the poll screens.
class PollFormatters {
  const PollFormatters._();

  static final DateFormat _day = DateFormat('EEE, dd MMM yyyy', 'en_US');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy · h:mm a', 'en_US');

  /// Short date label, e.g. `Fri, 20 Nov 2026`.
  static String day(DateTime value) => _day.format(value);

  /// Deadline label, e.g. `20 Nov 2026 · 11:59 PM`.
  static String deadline(DateTime value) => _dateTime.format(value);

  /// `Today` / `Tomorrow` / the formatted date.
  static String relativeDay(AppLocalizations local, DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final difference = target.difference(today).inDays;
    if (difference == 0) return local.pollToday;
    if (difference == 1) return local.pollTomorrow;
    return day(value);
  }

  /// `8 of 14 members voted`.
  static String participation(AppLocalizations local, int voted, int total) => local.pollParticipation(voted, total);
}
