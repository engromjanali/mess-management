import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';

/// Parameters for UpdateApiLocaleUseCase
class UpdateApiLocaleParams {
  final String localeCode;

  const UpdateApiLocaleParams({required this.localeCode});
}

/// UseCase to update API client locale headers
/// 
/// This use case ensures that the API client's locale headers are synchronized
/// with the user's language preference after a locale change
@lazySingleton
class UpdateApiLocaleUseCase implements UseCase<void, UpdateApiLocaleParams> {
  final SettingsRepository _repository;

  UpdateApiLocaleUseCase(this._repository);

  @override
  ResultVoid call(UpdateApiLocaleParams params) {
    return _repository.updateApiLocale(params.localeCode);
  }
}
