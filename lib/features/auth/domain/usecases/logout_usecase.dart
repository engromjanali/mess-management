import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';

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
