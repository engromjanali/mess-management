import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/meal_member_entity.dart';
import '../repositories/meal_admin_repository.dart';

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
