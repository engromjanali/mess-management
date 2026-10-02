import 'package:dio/dio.dart';
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
  Future<UserModel> login({required String email, required String password}) async {
    // `email` carries either an email or a phone number (with dial code).
    final type = email.contains('@') ? 'email' : 'phone';
    return _apiService.login({'type': type, type: email, 'password': password});
  }

  @override
  Future<UserModel> register({required String fullName, required String email, required String password, String? phone}) async {
    return _apiService.register({'full_name': fullName, 'email': email, 'password': password, if (phone != null && phone.isNotEmpty) 'phone': phone});
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    final type = email.contains('@') ? 'email' : 'phone';
    await _apiService.forgotPassword({'type': type, type: email});
  }

  @override
  Future<void> resetPassword({required String email, required String otp, required String password}) async {
    await _apiService.resetPassword({'email': email, 'otp': otp, 'password': password});
  }

  @override
  Future<void> logout() async {
    await _apiService.logout();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _apiService.getCurrentUser();
  }

  @override
  Future<UserModel> updateProfile({required String fullName, required String email, required String phone, String? address, List<int>? photoBytes, String? photoName}) async {
    final body = <String, dynamic>{'full_name': fullName, 'email': email, 'phone': phone, 'address': address ?? ''};
    if (photoBytes == null) return _apiService.updateProfile(body);
    // A new photo is sent as multipart; the backend stores it in Cloudinary.
    return _apiService.updateProfile(FormData.fromMap({...body, 'photo': MultipartFile.fromBytes(photoBytes, filename: photoName ?? 'profile.jpg')}));
  }
}
