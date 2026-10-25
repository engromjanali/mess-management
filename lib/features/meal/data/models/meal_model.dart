import 'package:clean_boilerplate/features/meal/domain/entities/meal_entity.dart';

/// Data-layer DTO for one day of the user's meals.
class MealModel {
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const MealModel({required this.date, this.breakfast = 0, this.lunch = 0, this.dinner = 0});

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      date: DateTime.parse(json['date'] as String),
      breakfast: (json['breakfast'] as num?)?.toDouble() ?? 0,
      lunch: (json['lunch'] as num?)?.toDouble() ?? 0,
      dinner: (json['dinner'] as num?)?.toDouble() ?? 0,
    );
  }

  MealEntity toEntity() => MealEntity(date: date, breakfast: breakfast, lunch: lunch, dinner: dinner);
}

/// Data-layer DTO for the user's meal overview (`GET /api/v1/user/meals`).
class MealOverviewModel {
  final String userName;
  final double mealRate;
  final List<MealModel> days;

  const MealOverviewModel({required this.userName, required this.mealRate, required this.days});

  factory MealOverviewModel.fromJson(Map<String, dynamic> json) {
    return MealOverviewModel(
      userName: json['user_name'] as String? ?? '',
      mealRate: (json['meal_rate'] as num?)?.toDouble() ?? 0,
      days: (json['days'] as List<dynamic>? ?? []).map((item) => MealModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  MealOverviewEntity toEntity() => MealOverviewEntity(userName: userName, mealRate: mealRate, days: days.map((d) => d.toEntity()).toList());
}
