import 'package:clean_boilerplate/features/meal/data/models/meal_admin_model.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';

/// Contract for any source that can provide & mutate admin meal data.
abstract class MealAdminDataSource {
  Future<MealAdminModel> getAdminData();

  /// Adds [meals] on [date] in one action; fails if that day already has meals.
  Future<MealAdminModel> addMealsForDay({required DateTime date, required List<MemberMealEntity> meals});

  Future<MealAdminModel> updateMemberMeal({required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner});

  Future<MealAdminModel> deleteMemberMeal({required String memberId, required DateTime date});
}
