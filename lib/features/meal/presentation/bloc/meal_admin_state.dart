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

  /// Data loaded, with the active member/date filters. [busy] is true while a
  /// refresh or add/edit/delete runs — the data stays shown with progress.
  const factory MealAdminState.loaded({required MealAdminEntity data, String? selectedMemberId, DateTime? selectedDate, @Default(false) bool busy}) = MealAdminLoaded;

  /// Loading or an action failed (after an action, the loaded state follows).
  const factory MealAdminState.error(String message) = MealAdminError;
}
