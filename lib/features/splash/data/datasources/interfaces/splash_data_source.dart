import 'package:clean_boilerplate/features/splash/data/models/config_model.dart';

abstract interface class SplashDataSource {
  Future<ConfigModel> getConfig();
}
