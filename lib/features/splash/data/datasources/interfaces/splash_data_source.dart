import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/splash/data/models/config_model.dart';

abstract interface class SplashDataSource {
  ResultFuture<ConfigModel> getConfig();
}
