import '../../../../config/util/result.dart';
import '../entities/meal_member_entity.dart';

/// Admin meal-management repository contract (domain abstraction).
///
/// Lets a manager record, edit and remove meals for any member on any date.
abstract class MealAdminRepository {
  /// Loads the member roster, meal rate and all per-member day records.
  ResultFuture<MealAdminEntity> getAdminData();

  /// Adds or overwrites the meal counts for [memberId] on [date], returning
  /// the refreshed admin data.
  ResultFuture<MealAdminEntity> saveMemberMeal({
    required String memberId,
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  });

  /// Removes the record for [memberId] on [date], returning refreshed data.
  ResultFuture<MealAdminEntity> deleteMemberMeal({
    required String memberId,
    required DateTime date,
  });
}
