import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';

abstract class SplashRepository {
  ResultFuture<ConfigEntity> getConfig();
}
