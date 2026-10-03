import 'package:equatable/equatable.dart';

/// A single day's meal record for the current user, split into the three
/// canonical meals. `total` is the sum used for billing against the meal rate.
class MealEntity extends Equatable {
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const MealEntity({required this.date, this.breakfast = 0, this.lunch = 0, this.dinner = 0});

  double get total => breakfast + lunch + dinner;

  bool sameDay(DateTime other) => date.year == other.year && date.month == other.month && date.day == other.day;

  @override
  List<Object?> get props => [date, breakfast, lunch, dinner];
}

/// Aggregated meal overview for the meal screen — the user's full day history
/// plus the meal rate, with convenience roll-ups used across the UI.
class MealOverviewEntity extends Equatable {
  final String userName;
  final double mealRate;

  /// All recorded days (any order); the getters normalise as needed.
  final List<MealEntity> days;

  const MealOverviewEntity({required this.userName, required this.mealRate, required this.days});

  double get totalMeals => days.fold<double>(0, (sum, d) => sum + d.total);

  double get mealCost => totalMeals * mealRate;

  double get averagePerDay => days.isEmpty ? 0 : totalMeals / days.length;

  /// The entry for [date]'s day, or an empty (zeroed) one if none was recorded.
  MealEntity dayFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return days.firstWhere((d) => d.sameDay(key), orElse: () => MealEntity(date: key));
  }

  /// Most-recent-first day list (for the history view).
  List<MealEntity> get recentFirst {
    final sorted = [...days]..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// The seven calendar days ending on [now], oldest first, with an empty
  /// entry for any day without meals (for the week chart).
  List<MealEntity> weekEndingOn(DateTime now) {
    return [for (var back = 6; back >= 0; back--) dayFor(DateTime(now.year, now.month, now.day - back))];
  }

  @override
  List<Object?> get props => [userName, mealRate, days];
}
