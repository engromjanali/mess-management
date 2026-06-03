import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/home_repository.dart';

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
