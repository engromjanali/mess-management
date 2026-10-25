import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';

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
