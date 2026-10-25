import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';
import 'package:clean_boilerplate/features/settings/domain/usecases/get_locale_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_locale_usecase_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late GetLocaleUseCase useCase;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    provideDummy<Result<String>>(Success(data: 'en'));
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    useCase = GetLocaleUseCase(mockSettingsRepository);
  });

  const tLocaleCode = 'en';

  test('should get locale code from the repository', () async {
    // arrange
    when(mockSettingsRepository.getLocale())
        .thenAnswer((_) async => Success(data: tLocaleCode));
    // act
    final result = await useCase(const NoParams());
    // assert
    expect(result, equals(Success(data: tLocaleCode)));
    verify(mockSettingsRepository.getLocale());
    verifyNoMoreInteractions(mockSettingsRepository);
  });
}
