import 'package:clean_boilerplate/features/meal/domain/entities/meal_entity.dart';

/// Data-layer DTO for a single day's meal record.
///
/// Plain DTO (no JSON codegen) while served from a local mock source. Add
/// `fromJson`/`toJson` here when a real API is wired up — the domain and
/// presentation layers won't change.
class MealModel {
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const MealModel({required this.date, this.breakfast = 0, this.lunch = 0, this.dinner = 0});

  MealModel copyWith({double? breakfast, double? lunch, double? dinner}) {
    return MealModel(date: date, breakfast: breakfast ?? this.breakfast, lunch: lunch ?? this.lunch, dinner: dinner ?? this.dinner);
  }

  MealEntity toEntity() => MealEntity(date: date, breakfast: breakfast, lunch: lunch, dinner: dinner);
}

/// Data-layer DTO for the full meal overview.
class MealOverviewModel {
  final String userName;
  final double mealRate;
  final List<MealModel> days;

  const MealOverviewModel({required this.userName, required this.mealRate, required this.days});

  MealOverviewEntity toEntity() => MealOverviewEntity(userName: userName, mealRate: mealRate, days: days.map((d) => d.toEntity()).toList());
}
