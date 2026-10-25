import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/settings/domain/entities/theme_mode.dart';
import 'package:mess_pilot/features/settings/domain/repositories/settings_repository.dart';
import 'package:mess_pilot/features/settings/data/datasources/interfaces/settings_data_source.dart';

/// Settings repository implementation (concrete class in data layer)
@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDataSource _dataSource;
  final ApiClient _apiClient;

  SettingsRepositoryImpl(this._dataSource, this._apiClient);

  @override
  ResultFuture<AppThemeMode> getThemeMode() async {
    try {
      final themeString = await _dataSource.getThemeMode();
      final themeMode = themeString.toAppThemeMode();
      return Result.success(data: themeMode);
    } catch (e) {
      return Result.failure(error: CacheFailure(message: 'Failed to get theme mode: ${e.toString()}'));
    }
  }

  @override
  ResultVoid setThemeMode(AppThemeMode mode) async {
    try {
      await _dataSource.saveThemeMode(mode.toStringValue());
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: CacheFailure(message: 'Failed to save theme mode: ${e.toString()}'));
    }
  }

  @override
  ResultFuture<String> getLocale() async {
    try {
      final localeCode = await _dataSource.getLocale();
      return Result.success(data: localeCode);
    } catch (e) {
      return Result.failure(error: CacheFailure(message: 'Failed to get locale: ${e.toString()}'));
    }
  }

  @override
  ResultVoid setLocale(String localeCode) async {
    try {
      await _dataSource.saveLocale(localeCode);
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: CacheFailure(message: 'Failed to save locale: ${e.toString()}'));
    }
  }

  @override
  ResultVoid updateApiLocale(String localeCode) async {
    try {
      await _apiClient.updateLocale(localeCode);
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: CacheFailure(message: 'Failed to update API locale: ${e.toString()}'));
    }
  }
}
