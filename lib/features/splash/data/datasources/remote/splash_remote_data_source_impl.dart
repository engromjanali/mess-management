import 'package:clean_boilerplate/features/splash/data/datasources/remote/splash_api_service.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/features/splash/data/datasources/interfaces/splash_data_source.dart';
import 'package:clean_boilerplate/features/splash/data/models/config_model.dart';

@LazySingleton(as: SplashDataSource)
class SplashRemoteDataSourceImpl implements SplashDataSource {
  final SplashApiService _splashApiService;

  SplashRemoteDataSourceImpl(this._splashApiService);
  @override
  Future<ConfigModel> getConfig() {
    return _splashApiService.getConfig();
  }
}
