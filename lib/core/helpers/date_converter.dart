import 'package:intl/intl.dart';

class DateConverter {
  const DateConverter._();

  static String orderDateTime(DateTime dateTime) {
    return DateFormat('d MMM, yyyy h:mm a').format(dateTime);
  }

  static String timeAgoLocalized(String? time, dynamic local, {String defaultText = ''}) {
    if (time == null || time.isEmpty) {
      return defaultText;
    }

    try {
      final DateTime dateTime = DateTime.parse(time);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);

      final bool isFuture = difference.isNegative;
      final Duration absDifference = difference.abs();

      final int seconds = absDifference.inSeconds;
      final int minutes = absDifference.inMinutes;
      final int hours = absDifference.inHours;
      final int days = absDifference.inDays;

      if (isFuture) {
        return local.time_ago_now;
      }

      if (seconds < 60) {
        final num = seconds <= 1 ? 1 : seconds;
        return local.time_ago_seconds(num);
      } else if (minutes < 60) {
        return local.time_ago_minutes(minutes);
      } else if (hours < 24) {
        final remainingMinutes = minutes % 60;
        if (remainingMinutes > 0) {
          return local.time_ago_hours(hours, remainingMinutes);
        }
        return local.time_ago_hours_only(hours);
      } else if (days < 7) {
        return local.time_ago_days(days);
      } else if (days < 30) {
        final weeks = (days / 7).floor();
        return local.time_ago_weeks(weeks);
      } else if (days < 365) {
        final months = (days / 30).floor();
        return local.time_ago_months(months);
      } else {
        final years = (days / 365).floor();
        return local.time_ago_years(years);
      }
    } catch (e) {
      return time;
    }
  }
}
