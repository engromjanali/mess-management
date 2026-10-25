import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';

/// Parameters for SetThemeModeUseCase
class SetThemeModeParams extends Equatable {
  final AppThemeMode mode;

  const SetThemeModeParams({required this.mode});

  @override
  List<Object?> get props => [mode];
}

/// UseCase to set a new theme mode
@lazySingleton
class SetThemeModeUseCase implements UseCase<void, SetThemeModeParams> {
  final SettingsRepository _repository;

  SetThemeModeUseCase(this._repository);

  @override
  ResultVoid call(SetThemeModeParams params) {
    return _repository.setThemeMode(params.mode);
  }
}
