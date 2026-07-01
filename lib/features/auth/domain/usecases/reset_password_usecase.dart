import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';

/// Reset-password use case parameters
class ResetPasswordParams {
  final String email;
  final String otp;
  final String password;

  const ResetPasswordParams({required this.email, required this.otp, required this.password});
}

/// Reset-password use case - sets a new password using the emailed OTP
@lazySingleton
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  @override
  ResultFuture<void> call(ResetPasswordParams params) {
    return _repository.resetPassword(email: params.email, otp: params.otp, password: params.password);
  }
}
