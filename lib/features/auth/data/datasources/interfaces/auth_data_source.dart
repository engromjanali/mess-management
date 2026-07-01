import 'package:clean_boilerplate/features/auth/data/models/user_model.dart';

/// Abstract data source interface for authentication
///
/// This interface defines the contract for both remote and local data sources.
/// Implementations:
/// - AuthRemoteDataSourceImpl: Handles API calls
/// - AuthLocalDataSourceImpl: Handles local storage (future implementation)
abstract class AuthDataSource {
  /// Authenticate user with email and password
  Future<UserModel> login({required String email, required String password});

  /// Register a new account and return the signed-in user
  Future<UserModel> register({required String fullName, required String email, required String password, String? phone});

  /// Request a password-reset OTP for the given email
  Future<void> forgotPassword({required String email});

  /// Reset the password using the emailed OTP
  Future<void> resetPassword({required String email, required String otp, required String password});

  /// Log out the current user
  Future<void> logout();

  /// Get the currently authenticated user
  Future<UserModel?> getCurrentUser();
}
