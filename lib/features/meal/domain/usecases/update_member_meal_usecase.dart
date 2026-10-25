import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/domain/repositories/meal_admin_repository.dart';

class UpdateMemberMealParams extends Equatable {
  final String memberId;
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const UpdateMemberMealParams({required this.memberId, required this.date, required this.breakfast, required this.lunch, required this.dinner});

  @override
  List<Object?> get props => [memberId, date, breakfast, lunch, dinner];
}

@lazySingleton
class UpdateMemberMealUseCase implements UseCase<MealAdminEntity, UpdateMemberMealParams> {
  final MealAdminRepository _repository;

  UpdateMemberMealUseCase(this._repository);

  @override
  ResultFuture<MealAdminEntity> call(UpdateMemberMealParams params) {
    return _repository.updateMemberMeal(memberId: params.memberId, date: params.date, breakfast: params.breakfast, lunch: params.lunch, dinner: params.dinner);
  }
}
