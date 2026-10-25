import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/splash/data/models/config_model.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class SplashApiService {
  final ApiClient _apiClient;

  SplashApiService(this._apiClient);

  /// Throws app exceptions on failure (via [ApiClient]); the repository wraps
  /// this with `guardResult`. See the standard flow in `error_handler.dart`.
  Future<ConfigModel> getConfig() async {
    final response = await _apiClient.get(AppConstants.configEndPoint);
    return ConfigModel.fromJson(response.data as Map<String, dynamic>);
  }
}
