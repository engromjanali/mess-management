import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/meal_entity.dart';
import '../repositories/meal_repository.dart';

/// Parameters for [UpdateMealUseCase].
class UpdateMealParams extends Equatable {
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const UpdateMealParams({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  @override
  List<Object?> get props => [date, breakfast, lunch, dinner];
}

/// Updates the meal counts for a given day and returns the fresh overview.
@lazySingleton
class UpdateMealUseCase
    implements UseCase<MealOverviewEntity, UpdateMealParams> {
  final MealRepository _repository;

  UpdateMealUseCase(this._repository);

  @override
  ResultFuture<MealOverviewEntity> call(UpdateMealParams params) {
    return _repository.updateMeal(
      date: params.date,
      breakfast: params.breakfast,
      lunch: params.lunch,
      dinner: params.dinner,
    );
  }
}
