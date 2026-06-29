import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/domain/usecases/get_theme_mode_usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/usecases/set_theme_mode_usecase.dart';

part 'theme_state.dart';
part 'theme_bloc.freezed.dart';

/// Theme BLoC - Handles theme switching logic with clean architecture
@lazySingleton
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final GetThemeModeUseCase _getThemeModeUseCase;
  final SetThemeModeUseCase _setThemeModeUseCase;

  ThemeBloc(this._getThemeModeUseCase, this._setThemeModeUseCase) : super(const ThemeState.system()) {
    on<ThemeEvent>(_onThemeEvent);
  }

  /// Handle all theme events using pattern matching
  Future<void> _onThemeEvent(ThemeEvent event, Emitter<ThemeState> emit) async {
    await event.when(loadThemeMode: () => _handleLoadThemeMode(emit), changeThemeMode: (mode) => _handleChangeThemeMode(mode, emit));
  }

  /// Handle load theme mode request
  Future<void> _handleLoadThemeMode(Emitter<ThemeState> emit) async {
    final result = await _getThemeModeUseCase(const NoParams());

    result.when(
      success: (success) {
        // Emit appropriate state based on theme mode
        if (success.data == AppThemeMode.dark) {
          emit(const ThemeState.dark());
        } else if (success.data == AppThemeMode.system) {
          emit(const ThemeState.system());
        } else {
          emit(const ThemeState.light());
        }
      },
      failure: (_) {
        // On error, keep current state (no error state needed for theme)
        // Could log error here if needed
      },
    );
  }

  /// Handle change theme mode request
  Future<void> _handleChangeThemeMode(AppThemeMode mode, Emitter<ThemeState> emit) async {
    final result = await _setThemeModeUseCase(SetThemeModeParams(mode: mode));

    result.when(
      success: (_) {
        // Emit new theme state
        if (mode == AppThemeMode.dark) {
          emit(const ThemeState.dark());
        } else if (mode == AppThemeMode.system) {
          emit(const ThemeState.system());
        } else {
          emit(const ThemeState.light());
        }
      },
      failure: (_) {
        // On error, keep current state
        // Could log error here if needed
      },
    );
  }
}
