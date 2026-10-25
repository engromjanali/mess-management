import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/settings/data/datasources/interfaces/settings_data_source.dart';
import 'package:clean_boilerplate/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_repository_impl_test.mocks.dart';

@GenerateMocks([SettingsDataSource, ApiClient])
void main() {
  late SettingsRepositoryImpl repository;
  late MockSettingsDataSource mockSettingsDataSource;
  late MockApiClient mockApiClient;

  setUpAll(() {
    provideDummy<Result<AppThemeMode>>(Success(data: AppThemeMode.light));
    provideDummy<Result<String>>(Success(data: 'en'));
    provideDummy<Result<void>>(Success(data: null));
  });

  setUp(() {
    mockSettingsDataSource = MockSettingsDataSource();
    mockApiClient = MockApiClient();
    repository = SettingsRepositoryImpl(mockSettingsDataSource, mockApiClient);
  });

  const tThemeString = 'light';
  const tThemeMode = AppThemeMode.light;
  const tLocaleCode = 'en';

  group('getThemeMode', () {
    test('should return theme mode from data source', () async {
      // arrange
      when(mockSettingsDataSource.getThemeMode())
          .thenAnswer((_) async => tThemeString);
      // act
      final result = await repository.getThemeMode();
      // assert
      expect(result, equals(Success(data: tThemeMode)));
      verify(mockSettingsDataSource.getThemeMode());
      verifyNoMoreInteractions(mockSettingsDataSource);
    });

    test('should return CacheFailure when data source throws exception', () async {
      // arrange
      when(mockSettingsDataSource.getThemeMode()).thenThrow(Exception());
      // act
      final result = await repository.getThemeMode();
      // assert
      expect(result.isFailure, true);
      verify(mockSettingsDataSource.getThemeMode());
      verifyNoMoreInteractions(mockSettingsDataSource);
    });
  });

  group('setThemeMode', () {
    test('should call saveThemeMode on data source', () async {
      // arrange
      when(mockSettingsDataSource.saveThemeMode(any))
          .thenAnswer((_) async => null);
      // act
      final result = await repository.setThemeMode(tThemeMode);
      // assert
      expect(result.isSuccess, true);
      verify(mockSettingsDataSource.saveThemeMode('light'));
      verifyNoMoreInteractions(mockSettingsDataSource);
    });
  });

  group('getLocale', () {
    test('should return locale code from data source', () async {
      // arrange
      when(mockSettingsDataSource.getLocale())
          .thenAnswer((_) async => tLocaleCode);
      // act
      final result = await repository.getLocale();
      // assert
      expect(result, equals(Success(data: tLocaleCode)));
      verify(mockSettingsDataSource.getLocale());
      verifyNoMoreInteractions(mockSettingsDataSource);
    });
  });

  group('setLocale', () {
    test('should call saveLocale on data source', () async {
      // arrange
      when(mockSettingsDataSource.saveLocale(any))
          .thenAnswer((_) async => null);
      // act
      final result = await repository.setLocale(tLocaleCode);
      // assert
      expect(result.isSuccess, true);
      verify(mockSettingsDataSource.saveLocale(tLocaleCode));
      verifyNoMoreInteractions(mockSettingsDataSource);
    });
  });

  group('updateApiLocale', () {
    test('should call updateLocale on api client', () async {
      // arrange
      when(mockApiClient.updateLocale(any))
          .thenAnswer((_) async => null);
      // act
      final result = await repository.updateApiLocale(tLocaleCode);
      // assert
      expect(result.isSuccess, true);
      verify(mockApiClient.updateLocale(tLocaleCode));
      verifyNoMoreInteractions(mockApiClient);
    });
  });
}
