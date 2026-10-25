import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';

/// Login use case parameters
class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}

/// Login use case - Single responsibility: handle login business logic
@lazySingleton
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  ResultFuture<UserEntity> call(LoginParams params) {
    return _repository.login(email: params.email, password: params.password);
  }
}
