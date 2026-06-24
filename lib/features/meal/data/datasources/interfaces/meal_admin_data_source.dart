import '../../models/meal_admin_model.dart';

/// Contract for any source that can provide & mutate admin meal data.
abstract class MealAdminDataSource {
  Future<MealAdminModel> getAdminData();

  /// Sets the same B/L/D for **every** member on [date] in one action.
  Future<MealAdminModel> addMealForAll({
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  });

  Future<MealAdminModel> saveMemberMeal({
    required String memberId,
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  });

  Future<MealAdminModel> deleteMemberMeal({
    required String memberId,
    required DateTime date,
  });
}
