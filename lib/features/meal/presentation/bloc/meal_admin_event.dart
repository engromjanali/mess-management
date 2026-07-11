import 'package:freezed_annotation/freezed_annotation.dart';

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

  /// Record the same B/L/D for every member on [date] at once (bulk entry).
  const factory MealAdminEvent.addForAll({required DateTime date, required double breakfast, required double lunch, required double dinner}) = MealAdminAddForAll;

  /// Add a member's meal for a date.
  const factory MealAdminEvent.save({required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner}) = MealAdminSave;

  /// Update an existing member's meal for a date.
  const factory MealAdminEvent.update({required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner}) = MealAdminUpdate;

  /// Remove a member's meal record for a date.
  const factory MealAdminEvent.delete({required String memberId, required DateTime date}) = MealAdminDelete;
}
