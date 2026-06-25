import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/features/auth/data/models/user_model.dart';
import 'package:clean_boilerplate/features/auth/data/datasources/interfaces/auth_data_source.dart';
import 'package:clean_boilerplate/features/auth/data/datasources/remote/auth_api_service.dart';

/// Remote data source implementation for authentication
@LazySingleton(as: AuthDataSource)
class AuthRemoteDataSourceImpl implements AuthDataSource {
  final AuthApiService _apiService;

  AuthRemoteDataSourceImpl(this._apiService);

  @override
  Future<UserModel> login({required String email, required String password,}) async {
    return _apiService.login({'email': email, 'password': password});
  }

  @override
  Future<void> logout() async {
    await _apiService.logout();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _apiService.getCurrentUser();
  }
}
