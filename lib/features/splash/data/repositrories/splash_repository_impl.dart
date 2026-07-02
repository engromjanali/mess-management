import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/error_handler.dart';
import 'package:clean_boilerplate/features/splash/data/datasources/interfaces/splash_data_source.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:clean_boilerplate/features/splash/domain/repositories/splash_repository.dart';
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
