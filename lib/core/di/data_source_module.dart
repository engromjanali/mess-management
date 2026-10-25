import 'package:clean_boilerplate/features/auth/data/datasources/remote/auth_api_service.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';

/// Data source module for dependency injection
@module
abstract class DataSourceModule {
  @lazySingleton
  AuthApiService authApiService(ApiClient apiClient) => AuthApiService(apiClient);
}
