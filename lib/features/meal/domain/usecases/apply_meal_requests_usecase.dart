import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_member_entity.dart';
import 'package:mess_pilot/features/meal/domain/repositories/meal_admin_repository.dart';

class ApplyMealRequestsParams extends Equatable {
  const ApplyMealRequestsParams({required this.date, required this.requestIds, required this.meals});

  final DateTime date;
  final List<String> requestIds;
  final List<MemberMealEntity> meals;

  @override
  List<Object?> get props => [date, requestIds, meals];
}

@lazySingleton
class ApplyMealRequestsUseCase implements UseCase<MealAdminEntity, ApplyMealRequestsParams> {
  const ApplyMealRequestsUseCase(this._repository);

  final MealAdminRepository _repository;

  @override
  ResultFuture<MealAdminEntity> call(ApplyMealRequestsParams params) =>
      _repository.applyMealRequests(date: params.date, requestIds: params.requestIds, meals: params.meals);
}
