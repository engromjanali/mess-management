import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/errors/error_handler.dart';
import 'package:mess_pilot/features/splash/data/datasources/interfaces/splash_data_source.dart';
import 'package:mess_pilot/features/splash/domain/entities/config_entity.dart';
import 'package:mess_pilot/features/splash/domain/repositories/splash_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SplashRepository)
class SplashRepositoryImpl implements SplashRepository {
  final SplashDataSource _splashDataSource;

  SplashRepositoryImpl(this._splashDataSource);

  @override
  ResultFuture<ConfigEntity> getConfig() async {
    return guardResult(() async => (await _splashDataSource.getConfig()).toEntity());
  }
}
