import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/home/domain/entities/dashboard_entity.dart';
import 'package:mess_pilot/features/home/domain/repositories/home_repository.dart';

/// Loads the home dashboard. Single responsibility, no parameters.
@lazySingleton
class GetDashboardUseCase implements UseCase<DashboardEntity, NoParams> {
  final HomeRepository _repository;

  GetDashboardUseCase(this._repository);

  @override
  ResultFuture<DashboardEntity> call(NoParams params) {
    return _repository.getDashboard();
  }
}
