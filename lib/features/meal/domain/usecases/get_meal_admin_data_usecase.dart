import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/domain/repositories/meal_admin_repository.dart';

/// Loads the admin meal-management data (members, rate, all records).
@lazySingleton
class GetMealAdminDataUseCase implements UseCase<MealAdminEntity, NoParams> {
  final MealAdminRepository _repository;

  GetMealAdminDataUseCase(this._repository);

  @override
  ResultFuture<MealAdminEntity> call(NoParams params) {
    return _repository.getAdminData();
  }
}
