import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_entity.dart';

/// Meal repository contract (abstraction in the domain layer).
abstract class MealRepository {
  /// Loads the current user's meal overview (history + meal rate).
  ResultFuture<MealOverviewEntity> getMealOverview();

  /// Persists the meal counts for [date] and returns the updated overview.
  ResultFuture<MealOverviewEntity> updateMeal({
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  });
}
