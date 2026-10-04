import 'dart:math';

import 'package:intl/intl.dart';

/// Display helpers for seasons.
class SeasonFormatters {
  SeasonFormatters._();

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static const String _letters = 'abcdefghijklmnopqrstuvwxyz';
  static final Random _random = Random();

  static String date(DateTime date) => _date.format(date);

  /// Placeholder name for an auto-created season: `season-` + 3 random letters.
  static String autoName() => 'season-${List.generate(3, (_) => _letters[_random.nextInt(_letters.length)]).join()}';
}
