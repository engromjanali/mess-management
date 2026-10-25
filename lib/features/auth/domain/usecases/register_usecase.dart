import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';

/// Register use case parameters
class RegisterParams {
  final String fullName;
  final String email;
  final String password;
  final String? phone;

  const RegisterParams({required this.fullName, required this.email, required this.password, this.phone});
}

/// Register use case - creates an account and returns the signed-in user
@lazySingleton
class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  ResultFuture<UserEntity> call(RegisterParams params) {
    return _repository.register(fullName: params.fullName, email: params.email, password: params.password, phone: params.phone);
  }
}
