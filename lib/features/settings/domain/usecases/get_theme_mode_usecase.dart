import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';

/// UseCase to get the current theme mode
@lazySingleton
class GetThemeModeUseCase implements UseCase<AppThemeMode, NoParams> {
  final SettingsRepository _repository;

  GetThemeModeUseCase(this._repository);

  @override
  ResultFuture<AppThemeMode> call(NoParams params) {
    return _repository.getThemeMode();
  }
}
