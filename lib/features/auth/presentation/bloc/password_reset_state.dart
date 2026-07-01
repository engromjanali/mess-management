import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_reset_state.freezed.dart';

/// State machine for the forgot-password / reset-password flow.
@Freezed(toJson: false, fromJson: false)
class PasswordResetState with _$PasswordResetState {
  /// Step 1: awaiting the email to send an OTP to.
  const factory PasswordResetState.initial() = PasswordResetInitial;

  /// A request is in flight.
  const factory PasswordResetState.loading() = PasswordResetLoading;

  /// Step 2: an OTP was sent to [email]; awaiting OTP + new password.
  const factory PasswordResetState.otpSent(String email) = PasswordResetOtpSent;

  /// The password was reset successfully.
  const factory PasswordResetState.success() = PasswordResetSuccess;

  /// Something failed; [message] is user-facing. [email] carries the current
  /// step's email so the UI can stay on the OTP screen after an error.
  const factory PasswordResetState.error(String message, {String? email}) = PasswordResetError;
}
