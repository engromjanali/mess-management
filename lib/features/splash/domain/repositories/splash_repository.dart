import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/splash/domain/entities/config_entity.dart';

abstract class SplashRepository {
  ResultFuture<ConfigEntity> getConfig();
}
