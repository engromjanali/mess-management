import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/domain/repositories/meal_admin_repository.dart';

/// Parameters for [AddMealsForDayUseCase].
class AddMealsForDayParams extends Equatable {
  final DateTime date;
  final List<MemberMealEntity> meals;

  const AddMealsForDayParams({required this.date, required this.meals});

  @override
  List<Object?> get props => [date, meals];
}

/// Adds a day's meals for the given members in one all-or-nothing action.
@lazySingleton
class AddMealsForDayUseCase implements UseCase<MealAdminEntity, AddMealsForDayParams> {
  final MealAdminRepository _repository;

  AddMealsForDayUseCase(this._repository);

  @override
  ResultFuture<MealAdminEntity> call(AddMealsForDayParams params) {
    return _repository.addMealsForDay(date: params.date, meals: params.meals);
  }
}
