import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/meal_entity.dart';
import '../repositories/meal_repository.dart';

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
