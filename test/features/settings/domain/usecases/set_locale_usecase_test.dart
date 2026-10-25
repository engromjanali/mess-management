import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/features/settings/domain/usecases/set_locale_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'get_locale_usecase_test.mocks.dart'; // Reuse the mock

void main() {
  late SetLocaleUseCase useCase;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    provideDummy<Result<void>>(Success(data: null));
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    useCase = SetLocaleUseCase(mockSettingsRepository);
  });

  const tLocaleCode = 'en';

  test('should call setLocale on the repository', () async {
    // arrange
    when(mockSettingsRepository.setLocale(any))
        .thenAnswer((_) async => Success(data: null));
    // act
    final result = await useCase(const SetLocaleParams(localeCode: tLocaleCode));
    // assert
    expect(result, equals(const Success<void>(data: null)));
    verify(mockSettingsRepository.setLocale(tLocaleCode));
    verifyNoMoreInteractions(mockSettingsRepository);
  });
}
