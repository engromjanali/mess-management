import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_event.freezed.dart';

/// Meal events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class MealEvent with _$MealEvent {
  /// Initial load of the meal overview.
  const factory MealEvent.load() = MealLoad;

  /// Pull-to-refresh of the meal overview.
  const factory MealEvent.refresh() = MealRefresh;

  /// Update today's meal counts (from the today editor steppers).
  const factory MealEvent.updateToday({required double breakfast, required double lunch, required double dinner}) = MealUpdateToday;
}
