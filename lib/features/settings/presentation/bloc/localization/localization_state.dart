part of 'localization_bloc.dart';

@Freezed(toJson: false, fromJson: false)
class LocalizationState with _$LocalizationState {
  /// Initial state with default locale
  const factory LocalizationState.initial(Locale locale) = _Initial;

  /// Locale loaded successfully
  const factory LocalizationState.loaded(Locale locale) = _Loaded;

  /// Error occurred while changing locale
  const factory LocalizationState.error(String message, Locale locale) = _Error;

  const LocalizationState._();

  /// Get the current locale from any state
  @override
  Locale get locale => when(initial: (locale) => locale, loaded: (locale) => locale, error: (_, locale) => locale);
}
