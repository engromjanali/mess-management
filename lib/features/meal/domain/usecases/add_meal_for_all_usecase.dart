import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/domain/repositories/meal_admin_repository.dart';

/// Parameters for [AddMealForAllUseCase].
class AddMealForAllParams extends Equatable {
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const AddMealForAllParams({required this.date, required this.breakfast, required this.lunch, required this.dinner});

  @override
  List<Object?> get props => [date, breakfast, lunch, dinner];
}

/// Records the same B/L/D for every member on a date in a single action — the
/// core "add meal for all at once" business rule.
@lazySingleton
class AddMealForAllUseCase implements UseCase<MealAdminEntity, AddMealForAllParams> {
  final MealAdminRepository _repository;

  AddMealForAllUseCase(this._repository);

  @override
  ResultFuture<MealAdminEntity> call(AddMealForAllParams params) {
    return _repository.addMealForAll(date: params.date, breakfast: params.breakfast, lunch: params.lunch, dinner: params.dinner);
  }
}
