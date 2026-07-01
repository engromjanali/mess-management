import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/auth/data/models/user_model.dart';

/// Auth API service using ApiClient.
///
/// The Django backend returns `{ access, refresh, user }` on login/register;
/// this service persists the tokens on the [ApiClient] and hands the caller the
/// parsed [UserModel].
class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  Future<UserModel> login(Map<String, dynamic> body) async {
    final response = await _apiClient.post(AppConstants.loginEndpoint, data: body);
    return _handleAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<UserModel> register(Map<String, dynamic> body) async {
    final response = await _apiClient.post(AppConstants.registerEndpoint, data: body);
    return _handleAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword(Map<String, dynamic> body) async {
    await _apiClient.post(AppConstants.forgotPasswordEndpoint, data: body);
  }

  Future<void> resetPassword(Map<String, dynamic> body) async {
    await _apiClient.post(AppConstants.resetPasswordEndpoint, data: body);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(AppConstants.logoutEndpoint);
    } finally {
      // Tokens are cleared regardless of whether the network call succeeds.
      await _apiClient.clearTokens();
    }
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(AppConstants.profileEndpoint);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Stores the tokens from an auth response and returns the embedded user.
  Future<UserModel> _handleAuthResponse(Map<String, dynamic> data) async {
    await _apiClient.updateToken(data['access'] as String?);
    await _apiClient.updateRefreshToken(data['refresh'] as String?);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}
