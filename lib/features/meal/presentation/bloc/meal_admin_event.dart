import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';

part 'meal_admin_event.freezed.dart';

/// Admin meal-management events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class MealAdminEvent with _$MealAdminEvent {
  /// Initial load of the admin meal data.
  const factory MealAdminEvent.load() = MealAdminLoad;

  /// Reload after an external change (pull-to-refresh).
  const factory MealAdminEvent.refresh() = MealAdminRefresh;

  /// Filter the records by member. `null` shows every member.
  const factory MealAdminEvent.selectMember(String? memberId) = MealAdminSelectMember;

  /// Filter the records by date. `null` shows every date.
  const factory MealAdminEvent.selectDate(DateTime? date) = MealAdminSelectDate;

  /// Add [meals] (one per member) for a day with no meals yet, all or none.
  const factory MealAdminEvent.addForDay({required DateTime date, required List<MemberMealEntity> meals}) = MealAdminAddForDay;

  /// Update an existing member's meal for a date.
  const factory MealAdminEvent.update({required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner}) = MealAdminUpdate;

  /// Remove a member's meal record for a date.
  const factory MealAdminEvent.delete({required String memberId, required DateTime date}) = MealAdminDelete;
}
