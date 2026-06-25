import 'package:clean_boilerplate/features/auth/data/models/user_model.dart';
import 'package:clean_boilerplate/features/auth/data/datasources/interfaces/auth_data_source.dart';

/// Local data source implementation for authentication
/// 
/// This is a placeholder for future local data source implementation.
/// When implemented, this could handle:
/// - Caching user data in local storage (Hive, SharedPreferences, SQLite)
/// - Offline authentication
/// - Session persistence
/// 
/// To enable this implementation:
/// 1. Implement the methods below with actual local storage logic
/// 2. Add @LazySingleton(as: AuthDataSource) annotation (or use Named registration)
/// 3. Update the repository to inject the correct data source
/// 4. Run code generation: dart run build_runner build --delete-conflicting-outputs
///
/// Note: Currently, AuthRemoteDataSourceImpl is registered as the default AuthDataSource.
/// To use both remote and local, consider using Named injection like:
/// @Named('remote') or @Named('local')
class AuthLocalDataSourceImpl implements AuthDataSource {
  AuthLocalDataSourceImpl();

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError(
      'Local authentication is not yet implemented. '
      'This is a placeholder for future local data source functionality.',
    );
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError(
      'Local logout is not yet implemented. '
      'This is a placeholder for future local data source functionality.',
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    throw UnimplementedError(
      'Local getCurrentUser is not yet implemented. '
      'This is a placeholder for future local data source functionality.',
    );
  }
}
