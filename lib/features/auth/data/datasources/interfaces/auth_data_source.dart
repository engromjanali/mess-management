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

  /// Log out the current user
  Future<void> logout();

  /// Get the currently authenticated user
  Future<UserModel?> getCurrentUser();
}
