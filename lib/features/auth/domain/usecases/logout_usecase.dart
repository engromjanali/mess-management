import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';

/// Logout use case
@lazySingleton
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  @override
  ResultFuture<void> call(NoParams params) {
    return _repository.logout();
  }
}
