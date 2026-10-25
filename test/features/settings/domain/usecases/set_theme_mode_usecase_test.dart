import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/domain/usecases/set_theme_mode_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'get_locale_usecase_test.mocks.dart'; // Reuse the mock

void main() {
  late SetThemeModeUseCase useCase;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    provideDummy<Result<void>>(Success(data: null));
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    useCase = SetThemeModeUseCase(mockSettingsRepository);
  });

  const tThemeMode = AppThemeMode.dark;

  test('should call setThemeMode on the repository', () async {
    // arrange
    when(mockSettingsRepository.setThemeMode(any))
        .thenAnswer((_) async => Success(data: null));
    // act
    final result = await useCase(const SetThemeModeParams(mode: tThemeMode));
    // assert
    expect(result, equals(const Success<void>(data: null)));
    verify(mockSettingsRepository.setThemeMode(tThemeMode));
    verifyNoMoreInteractions(mockSettingsRepository);
  });
}
