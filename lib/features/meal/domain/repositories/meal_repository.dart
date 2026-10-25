import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_entity.dart';

/// Meal repository contract (abstraction in the domain layer).
abstract class MealRepository {
  /// Loads the current user's meal overview (history + meal rate).
  ResultFuture<MealOverviewEntity> getMealOverview();
}
