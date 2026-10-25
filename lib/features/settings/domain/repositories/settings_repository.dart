import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/settings/domain/entities/theme_mode.dart';

/// Settings repository interface (abstraction in domain layer)
abstract class SettingsRepository {
  /// Get the current theme mode
  ResultFuture<AppThemeMode> getThemeMode();

  /// Set a new theme mode
  ResultVoid setThemeMode(AppThemeMode mode);

  /// Get the current locale code
  ResultFuture<String> getLocale();

  /// Set a new locale
  ResultVoid setLocale(String localeCode);

  /// Update API client locale headers
  ResultVoid updateApiLocale(String localeCode);
}
