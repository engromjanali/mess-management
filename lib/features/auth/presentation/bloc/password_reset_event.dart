import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_reset_event.freezed.dart';

/// Events for the forgot-password / reset-password flow.
@Freezed(toJson: false, fromJson: false)
class PasswordResetEvent with _$PasswordResetEvent {
  /// Request a reset OTP be emailed to [email].
  const factory PasswordResetEvent.otpRequested({required String email}) = OtpRequested;

  /// Submit the emailed [otp] together with the [password] to set.
  const factory PasswordResetEvent.passwordSubmitted({required String email, required String otp, required String password}) = PasswordSubmitted;

  /// Reset the flow back to its initial (request-OTP) step.
  const factory PasswordResetEvent.restarted() = PasswordResetRestarted;
}
