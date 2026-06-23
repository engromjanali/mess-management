import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/meal_member_entity.dart';
import '../repositories/meal_admin_repository.dart';

/// Parameters for [SaveMemberMealUseCase] (covers both add and edit).
class SaveMemberMealParams extends Equatable {
  final String memberId;
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const SaveMemberMealParams({
    required this.memberId,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  @override
  List<Object?> get props => [memberId, date, breakfast, lunch, dinner];
}

/// Adds a new meal record or edits an existing one for a member on a date.
@lazySingleton
class SaveMemberMealUseCase
    implements UseCase<MealAdminEntity, SaveMemberMealParams> {
  final MealAdminRepository _repository;

  SaveMemberMealUseCase(this._repository);

  @override
  ResultFuture<MealAdminEntity> call(SaveMemberMealParams params) {
    return _repository.saveMemberMeal(
      memberId: params.memberId,
      date: params.date,
      breakfast: params.breakfast,
      lunch: params.lunch,
      dinner: params.dinner,
    );
  }
}
