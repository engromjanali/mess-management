import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/features/settings/data/datasources/local/settings_local_data_source_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_local_data_source_impl_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  late SettingsLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    dataSource = SettingsLocalDataSourceImpl(mockSharedPreferences);
  });

  const tThemeKey = 'theme_mode';
  const tLocaleKey = AppConstants.languageCodeKey;
  const tDefaultTheme = 'light';

  group('getThemeMode', () {
    test('should return theme mode from SharedPreferences', () async {
      // arrange
      when(mockSharedPreferences.getString(any)).thenReturn('dark');
      // act
      final result = await dataSource.getThemeMode();
      // assert
      expect(result, 'dark');
      verify(mockSharedPreferences.getString(tThemeKey));
    });

    test('should return default theme when not found', () async {
      // arrange
      when(mockSharedPreferences.getString(any)).thenReturn(null);
      // act
      final result = await dataSource.getThemeMode();
      // assert
      expect(result, tDefaultTheme);
      verify(mockSharedPreferences.getString(tThemeKey));
    });
  });

  group('saveThemeMode', () {
    test('should call setString on SharedPreferences', () async {
      // arrange
      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);
      // act
      await dataSource.saveThemeMode('dark');
      // assert
      verify(mockSharedPreferences.setString(tThemeKey, 'dark'));
    });
  });

  group('getLocale', () {
    test('should return locale from SharedPreferences', () async {
      // arrange
      when(mockSharedPreferences.getString(any)).thenReturn('bn');
      // act
      final result = await dataSource.getLocale();
      // assert
      expect(result, 'bn');
      verify(mockSharedPreferences.getString(tLocaleKey));
    });

    test('should return default locale when not found', () async {
      // arrange
      when(mockSharedPreferences.getString(any)).thenReturn(null);
      // act
      final result = await dataSource.getLocale();
      // assert
      // Assuming AppConstants.languages.first.code is 'en' or similar. 
      // We check that it returns passed default from constants.
      expect(result, AppConstants.languages.first.code);
      verify(mockSharedPreferences.getString(tLocaleKey));
    });
  });

  test('Existing locale_code preference is preserved during migration', () async {
    when(mockSharedPreferences.getString(AppConstants.languageCodeKey)).thenReturn(null);
    when(mockSharedPreferences.getString('locale_code')).thenReturn('bn');
    expect(await dataSource.getLocale(), 'bn');
  });

  group('saveLocale', () {
    test('should call setString on SharedPreferences', () async {
      // arrange
      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);
      // act
      await dataSource.saveLocale('bn');
      // assert
      verify(mockSharedPreferences.setString(tLocaleKey, 'bn'));
    });
  });
}
