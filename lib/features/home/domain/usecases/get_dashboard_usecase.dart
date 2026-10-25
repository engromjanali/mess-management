import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/home/domain/entities/dashboard_entity.dart';
import 'package:clean_boilerplate/features/home/domain/repositories/home_repository.dart';

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
