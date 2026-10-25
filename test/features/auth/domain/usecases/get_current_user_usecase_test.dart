import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_current_user_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    provideDummy<Result<UserEntity?>>(Success(data: null));
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockAuthRepository);
  });

  const tUser = UserEntity(id: '1', email: 'test@example.com', name: 'Test User');

  test('should call getCurrentUser on repository', () async {
    // Arrange
    when(mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => Success(data: tUser));

    // Act
    final result = await useCase(NoParams());

    // Assert
    expect(result.data, tUser);
    verify(mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return Failure when getCurrentUser fails', () async {
    // Arrange
    const tFailure = CacheFailure(message: 'No user found');
    when(mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => Failure(error: tFailure));

    // Act
    final result = await useCase(NoParams());

    // Assert
    expect(result.isFailure, true);
    verify(mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
