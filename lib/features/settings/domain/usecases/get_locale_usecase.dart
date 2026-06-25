import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';

/// UseCase to get the current locale code
@lazySingleton
class GetLocaleUseCase implements UseCase<String, NoParams> {
  final SettingsRepository _repository;

  GetLocaleUseCase(this._repository);

  @override
  ResultFuture<String> call(NoParams params) {
    return _repository.getLocale();
  }
}
