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

  MealEntity copyWith({double? breakfast, double? lunch, double? dinner}) {
    return MealEntity(date: date, breakfast: breakfast ?? this.breakfast, lunch: lunch ?? this.lunch, dinner: dinner ?? this.dinner);
  }

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

  /// Today's entry, or an empty (zeroed) entry for today if none exists yet.
  MealEntity todayFor(DateTime now) {
    final key = DateTime(now.year, now.month, now.day);
    return days.firstWhere((d) => d.date.year == key.year && d.date.month == key.month && d.date.day == key.day, orElse: () => MealEntity(date: key));
  }

  /// Most-recent-first day list (for the history view).
  List<MealEntity> get recentFirst {
    final sorted = [...days]..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Oldest-to-newest last seven days (for the week chart).
  List<MealEntity> get lastSevenDays {
    final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length <= 7) return sorted;
    return sorted.sublist(sorted.length - 7);
  }

  @override
  List<Object?> get props => [userName, mealRate, days];
}
