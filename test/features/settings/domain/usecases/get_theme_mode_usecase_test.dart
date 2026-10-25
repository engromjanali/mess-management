import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/domain/usecases/get_theme_mode_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'get_locale_usecase_test.mocks.dart'; // Reuse the mock

void main() {
  late GetThemeModeUseCase useCase;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    provideDummy<Result<AppThemeMode>>(Success(data: AppThemeMode.light));
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    useCase = GetThemeModeUseCase(mockSettingsRepository);
  });

  const tThemeMode = AppThemeMode.light;

  test('should get theme mode from the repository', () async {
    // arrange
    when(mockSettingsRepository.getThemeMode())
        .thenAnswer((_) async => Success(data: tThemeMode));
    // act
    final result = await useCase(const NoParams());
    // assert
    expect(result, equals(Success(data: tThemeMode)));
    verify(mockSettingsRepository.getThemeMode());
    verifyNoMoreInteractions(mockSettingsRepository);
  });
}
