import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/features/settings/data/datasources/interfaces/settings_data_source.dart';

/// Local implementation of SettingsDataSource using SharedPreferences
@LazySingleton(as: SettingsDataSource)
class SettingsLocalDataSourceImpl implements SettingsDataSource {
  final SharedPreferences _prefs;

  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale_code';
  static const String _defaultTheme = 'system';

  SettingsLocalDataSourceImpl(this._prefs);

  @override
  Future<String> getThemeMode() async {
    return _prefs.getString(_themeKey) ?? _defaultTheme;
  }

  @override
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeKey, mode);
  }

  @override
  Future<String> getLocale() async {
    // Use first language from AppConstants.languages as default
    return _prefs.getString(_localeKey) ?? AppConstants.languages.first.code;
  }

  @override
  Future<void> saveLocale(String localeCode) async {
    await _prefs.setString(_localeKey, localeCode);
  }
}
