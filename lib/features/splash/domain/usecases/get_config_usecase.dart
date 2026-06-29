import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:clean_boilerplate/features/splash/domain/repositories/splash_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class GetConfigUseCase {
  final SplashRepository _splashRepository;

  GetConfigUseCase(this._splashRepository);

  ResultFuture<ConfigEntity> call() async {
    return _splashRepository.getConfig();
  }
}
