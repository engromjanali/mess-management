import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';

/// Forgot-password use case - requests an OTP for the given email
@lazySingleton
class ForgotPasswordUseCase implements UseCase<void, String> {
  final AuthRepository _repository;

  ForgotPasswordUseCase(this._repository);

  @override
  ResultFuture<void> call(String email) {
    return _repository.forgotPassword(email: email);
  }
}
