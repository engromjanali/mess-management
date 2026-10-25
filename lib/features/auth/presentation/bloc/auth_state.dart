import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';

part 'auth_state.freezed.dart';

/// Auth state using Freezed for better type safety and pattern matching
/// Note: No JSON serialization as states are runtime-only and contain entities
@Freezed(toJson: false, fromJson: false)
class AuthState with _$AuthState {
  /// Initial state
  const factory AuthState.initial() = AuthInitial;

  /// Loading state
  const factory AuthState.loading() = AuthLoading;

  /// Authenticated state
  const factory AuthState.authenticated(UserEntity user) = Authenticated;

  /// Unauthenticated state
  const factory AuthState.unauthenticated() = Unauthenticated;

  /// Auth error state
  const factory AuthState.error(String message) = AuthError;
}
