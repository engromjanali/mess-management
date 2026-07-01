import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

/// Auth events using Freezed for better type safety and less boilerplate
/// Note: No JSON serialization as events are runtime-only
@Freezed(toJson: false, fromJson: false)
class AuthEvent with _$AuthEvent {
  /// Login requested event
  const factory AuthEvent.loginRequested({required String email, required String password}) = LoginRequested;

  /// Register requested event
  const factory AuthEvent.registerRequested({required String fullName, required String email, required String password, String? phone}) = RegisterRequested;

  /// Logout requested event
  const factory AuthEvent.logoutRequested() = LogoutRequested;

  /// Check auth status event
  const factory AuthEvent.checkAuthStatus() = CheckAuthStatus;
}
