import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/splash/data/models/config_model.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class SplashApiService {
  final ApiClient _apiClient;

  SplashApiService(this._apiClient);

  ResultFuture<ConfigModel> getConfig() async {
    final response = await _apiClient.get(AppConstants.configEndPoint);

    return Result.fromDioResponse(response: response, parser: (data) => ConfigModel.fromJson(data!));
  }
}
