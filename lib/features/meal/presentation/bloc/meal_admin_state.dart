import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';

part 'meal_admin_state.freezed.dart';

/// Admin meal-management states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class MealAdminState with _$MealAdminState {
  /// Before any load has started.
  const factory MealAdminState.initial() = MealAdminInitial;

  /// Data is loading for the first time.
  const factory MealAdminState.loading() = MealAdminLoading;

  /// Data loaded successfully, with the active member/date filters.
  const factory MealAdminState.loaded({
    required MealAdminEntity data,
    String? selectedMemberId,
    DateTime? selectedDate,
  }) = MealAdminLoaded;

  /// Loading or a mutation failed.
  const factory MealAdminState.error(String message) = MealAdminError;
}
