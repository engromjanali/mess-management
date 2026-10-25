import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_entity.dart';
import 'package:mess_pilot/features/meal/domain/repositories/meal_repository.dart';

/// Loads the meal overview. Single responsibility, no parameters.
@lazySingleton
class GetMealOverviewUseCase implements UseCase<MealOverviewEntity, NoParams> {
  final MealRepository _repository;

  GetMealOverviewUseCase(this._repository);

  @override
  ResultFuture<MealOverviewEntity> call(NoParams params) {
    return _repository.getMealOverview();
  }
}
