import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/settings/domain/entities/theme_mode.dart';
import 'package:mess_pilot/features/settings/domain/repositories/settings_repository.dart';

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
