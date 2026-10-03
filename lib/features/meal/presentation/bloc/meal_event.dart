import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_event.freezed.dart';

/// Meal events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class MealEvent with _$MealEvent {
  /// Initial load of the meal overview.
  const factory MealEvent.load() = MealLoad;

  /// Pull-to-refresh of the meal overview.
  const factory MealEvent.refresh() = MealRefresh;
}
