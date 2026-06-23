import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/meal_member_entity.dart';
import '../repositories/meal_admin_repository.dart';

/// Parameters for [DeleteMemberMealUseCase].
class DeleteMemberMealParams extends Equatable {
  final String memberId;
  final DateTime date;

  const DeleteMemberMealParams({required this.memberId, required this.date});

  @override
  List<Object?> get props => [memberId, date];
}

/// Removes a member's meal record for a given day.
@lazySingleton
class DeleteMemberMealUseCase
    implements UseCase<MealAdminEntity, DeleteMemberMealParams> {
  final MealAdminRepository _repository;

  DeleteMemberMealUseCase(this._repository);

  @override
  ResultFuture<MealAdminEntity> call(DeleteMemberMealParams params) {
    return _repository.deleteMemberMeal(
      memberId: params.memberId,
      date: params.date,
    );
  }
}
