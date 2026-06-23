import '../../models/meal_model.dart';

/// Contract for any source that can provide & mutate meal data.
abstract class MealDataSource {
  Future<MealOverviewModel> getMealOverview();

  Future<MealOverviewModel> updateMeal({
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  });
}
