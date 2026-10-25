import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/settings/domain/entities/locale_entity.dart';
import 'package:mess_pilot/features/settings/domain/usecases/get_locale_usecase.dart';
import 'package:mess_pilot/features/settings/domain/usecases/set_locale_usecase.dart';
import 'package:mess_pilot/features/settings/domain/usecases/update_api_locale_usecase.dart';

part 'localization_event.dart';
part 'localization_state.dart';
part 'localization_bloc.freezed.dart';

/// Localization BLoC - Handles language switching with clean architecture
@lazySingleton
class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  final GetLocaleUseCase _getLocaleUseCase;
  final SetLocaleUseCase _setLocaleUseCase;
  final UpdateApiLocaleUseCase _updateApiLocaleUseCase;

  LocalizationBloc(this._getLocaleUseCase, this._setLocaleUseCase, this._updateApiLocaleUseCase) : super(const LocalizationState.initial(Locale(AppConstants.defaultLanguageCode))) {
    on<LocalizationEvent>(_onLocalizationEvent);
  }

  /// Handle all localization events using pattern matching
  Future<void> _onLocalizationEvent(LocalizationEvent event, Emitter<LocalizationState> emit) async {
    await event.when(loadLocale: () => _handleLoadLocale(emit), changeLocale: (localeCode) => _handleChangeLocale(localeCode, emit));
  }

  /// Handle load locale request
  Future<void> _handleLoadLocale(Emitter<LocalizationState> emit) async {
    final result = await _getLocaleUseCase(const NoParams());

    await result.when(
      success: (success) async {
        await _updateApiLocaleUseCase(UpdateApiLocaleParams(localeCode: success.data));
        final locale = AppLocale.fromCode(success.data);
        emit(LocalizationState.loaded(locale));
      },
      failure: (_) {
        // On error, use the default language
        emit(const LocalizationState.initial(Locale(AppConstants.defaultLanguageCode)));
      },
    );
  }

  /// Handle change locale request
  Future<void> _handleChangeLocale(String localeCode, Emitter<LocalizationState> emit) async {
    final locale = AppLocale.fromCode(localeCode);
    final result = await _setLocaleUseCase(SetLocaleParams(localeCode: localeCode));

    await result.when(
      success: (_) async {
        // Update API client locale headers after successfully saving locale
        await _updateApiLocaleUseCase(UpdateApiLocaleParams(localeCode: localeCode));
        emit(LocalizationState.loaded(locale));
      },
      failure: (failure) async {
        // On error, emit error state but keep current locale
        emit(LocalizationState.error('Failed to change locale', state.locale));
      },
    );
  }
}
