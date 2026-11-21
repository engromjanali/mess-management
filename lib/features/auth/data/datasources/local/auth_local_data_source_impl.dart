import 'dart:convert';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mess_pilot/features/auth/data/models/user_model.dart';
import 'package:mess_pilot/features/auth/data/datasources/interfaces/auth_data_source.dart';

/// Local data source implementation for authentication
///
/// Handles caching user data in local storage (SharedPreferences).
class AuthLocalDataSourceImpl implements AuthDataSource {
  AuthLocalDataSourceImpl();

  static const String _userCacheKey = 'cached_user_profile';

  UserModel? getCachedUser() {
    try {
      final jsonStr = getIt<SharedPreferences>().getString(_userCacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await getIt<SharedPreferences>().setString(_userCacheKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> clearUser() async {
    try {
      await getIt<SharedPreferences>().remove(_userCacheKey);
    } catch (_) {}
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    throw UnimplementedError('Local login is not supported.');
  }

  @override
  Future<UserModel> googleLogin({required String idToken}) async {
    throw UnimplementedError('Local Google login is not supported.');
  }

  @override
  Future<UserModel> register({required String fullName, required String email, required String password, String? phone}) async {
    throw UnimplementedError('Local registration is not supported.');
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    throw UnimplementedError('Local forgotPassword is not supported.');
  }

  @override
  Future<void> resetPassword({required String email, required String otp, required String password}) async {
    throw UnimplementedError('Local resetPassword is not supported.');
  }

  @override
  Future<void> logout() async {
    await clearUser();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return getCachedUser();
  }

  @override
  Future<UserModel> updateProfile({required String fullName, required String email, required String phone, String? address, List<int>? photoBytes, String? photoName, String? password}) async {
    throw UnimplementedError('Local updateProfile is not supported.');
  }

  @override
  Future<DateTime> requestAccountDeletion({required String password, String? reason}) async => DateTime.now().add(const Duration(days: 60));

  @override
  Future<void> cancelAccountDeletion() async {}
}
