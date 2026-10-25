import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'logout_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late LogoutUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    provideDummy<Result<void>>(Success(data: null));
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = LogoutUseCase(mockAuthRepository);
  });

  test('should call logout on repository', () async {
    // Arrange
    when(mockAuthRepository.logout())
        .thenAnswer((_) async => Success(data: null));

    // Act
    final result = await useCase(NoParams());

    // Assert
    expect(result.isSuccess, true);
    verify(mockAuthRepository.logout()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return Failure when logout fails', () async {
    // Arrange
    const tFailure = ServerFailure(message: 'Logout failed');
    when(mockAuthRepository.logout())
        .thenAnswer((_) async => Failure(error: tFailure));

    // Act
    final result = await useCase(NoParams());

    // Assert
    expect(result.isFailure, true);
    verify(mockAuthRepository.logout()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
