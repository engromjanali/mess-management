/// A mess season: the period meals, deposits and costs are counted in.
///
/// A mess can run many seasons at once; members work in the one they switch
/// to. Data can be added to a season up to its [endDate] (none while it
/// runs). A [disabled] season is kept but can't be switched to.
class SeasonEntity {
  const SeasonEntity({required this.id, required this.name, required this.startDate, this.endDate, this.disabled = false, this.memberCount = 0});

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final bool disabled;

  /// Members who haven't left (disabled members included).
  final int memberCount;

  SeasonStatus get status => disabled
      ? SeasonStatus.disabled
      : endDate == null
      ? SeasonStatus.running
      : SeasonStatus.ended;

  /// Which day of the season today is (day 1 = start date).
  int get day => DateTime.now().difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays + 1;
}

enum SeasonStatus { running, ended, disabled }
