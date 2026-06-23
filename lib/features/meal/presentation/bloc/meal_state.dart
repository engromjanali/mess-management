import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/meal_entity.dart';

part 'meal_state.freezed.dart';

/// Meal states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class MealState with _$MealState {
  /// Before any load has started.
  const factory MealState.initial() = MealInitial;

  /// Overview is loading for the first time.
  const factory MealState.loading() = MealLoading;

  /// Overview loaded successfully.
  const factory MealState.loaded(MealOverviewEntity overview) = MealLoaded;

  /// Loading failed.
  const factory MealState.error(String message) = MealError;
}
