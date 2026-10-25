import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    provideDummy<Result<UserEntity>>(
      Success(data: const UserEntity(id: 'dummy', email: 'dummy', name: 'dummy')),
    );
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = LoginUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = UserEntity(id: '1', email: tEmail, name: 'Test User');

  test('should call login on repository with correct parameters', () async {
    // Arrange
    when(mockAuthRepository.login(email: tEmail, password: tPassword))
        .thenAnswer((_) async => Success(data: tUser));

    // Act
    final result = await useCase(const LoginParams(email: tEmail, password: tPassword));

    // Assert
    expect(result.data, tUser);
    verify(mockAuthRepository.login(email: tEmail, password: tPassword)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return Failure when login fails', () async {
    // Arrange
    const tFailure = ServerFailure(message: 'Login failed');
    when(mockAuthRepository.login(email: tEmail, password: tPassword))
        .thenAnswer((_) async => Failure(error: tFailure));

    // Act
    final result = await useCase(const LoginParams(email: tEmail, password: tPassword));

    // Assert
    expect(result.isFailure, true);
    verify(mockAuthRepository.login(email: tEmail, password: tPassword)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
