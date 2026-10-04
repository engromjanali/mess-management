/// When a mess auto-creates a new season (and switches to it): a [day] of
/// the month from 1 to 28, which every month has, or [monthEnd] for the
/// month's last day (28th–31st).
class AutoCreateSeasonEntity {
  const AutoCreateSeasonEntity({required this.enabled, this.day = monthEnd});

  static const int monthEnd = 0;
  static const int lastFixedDay = 28;

  final bool enabled;
  final int day;

  bool get isMonthEnd => day == monthEnd;

  AutoCreateSeasonEntity copyWith({bool? enabled, int? day}) => AutoCreateSeasonEntity(enabled: enabled ?? this.enabled, day: day ?? this.day);
}
