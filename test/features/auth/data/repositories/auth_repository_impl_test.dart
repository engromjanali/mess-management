import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' hide Failure;
import 'package:clean_boilerplate/features/auth/data/datasources/interfaces/auth_data_source.dart';
import 'package:clean_boilerplate/features/auth/data/models/user_model.dart';
import 'package:clean_boilerplate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthDataSource])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthDataSource mockAuthDataSource;

  setUp(() {
    mockAuthDataSource = MockAuthDataSource();
    repository = AuthRepositoryImpl(mockAuthDataSource);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  final tUserModel = const UserModel(id: '1', email: tEmail, name: 'Test User');
  final tUserEntity = const UserEntity(id: '1', email: tEmail, name: 'Test User');

  group('login', () {
    test('should return UserEntity when login is successful', () async {
      // Arrange
      when(mockAuthDataSource.login(email: tEmail, password: tPassword))
          .thenAnswer((_) async => tUserModel);

      // Act
      final result = await repository.login(email: tEmail, password: tPassword);

      // Assert
      expect(result.data, tUserEntity);
      verify(mockAuthDataSource.login(email: tEmail, password: tPassword)).called(1);
    });

    test('should return AuthenticationFailure when UnauthorizedException occurs', () async {
      // Arrange
      when(mockAuthDataSource.login(email: tEmail, password: tPassword))
          .thenThrow(UnauthorizedException(message: 'Invalid credentials', statusCode: 401));

      // Act
      final result = await repository.login(email: tEmail, password: tPassword);

      // Assert
      expect(result.isFailure, true);
      expect((result as Failure).error, isA<AuthenticationFailure>());
      verify(mockAuthDataSource.login(email: tEmail, password: tPassword)).called(1);
    });

    test('should return ServerFailure when ServerException occurs', () async {
      // Arrange
      when(mockAuthDataSource.login(email: tEmail, password: tPassword))
          .thenThrow(ServerException(message: 'Server error', statusCode: 500));

      // Act
      final result = await repository.login(email: tEmail, password: tPassword);

      // Assert
      expect(result.isFailure, true);
      expect((result as Failure).error, isA<ServerFailure>());
      verify(mockAuthDataSource.login(email: tEmail, password: tPassword)).called(1);
    });
  });

  group('logout', () {
    test('should return Success(null) when logout is successful', () async {
      // Arrange
      when(mockAuthDataSource.logout()).thenAnswer((_) async {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isSuccess, true);
      expect(result.isSuccess, true);
      verify(mockAuthDataSource.logout()).called(1);
    });

    test('should return ServerFailure when logout fails', () async {
      // Arrange
      when(mockAuthDataSource.logout()).thenThrow(ServerException(message: 'Logout failed', statusCode: 500));

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isFailure, true);
      expect((result as Failure).error, isA<ServerFailure>());
      verify(mockAuthDataSource.logout()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return UserEntity when user is found', () async {
      // Arrange
      when(mockAuthDataSource.getCurrentUser()).thenAnswer((_) async => tUserModel);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.data, tUserEntity);
      verify(mockAuthDataSource.getCurrentUser()).called(1);
    });

    test('should return Success(null) when no user is found', () async {
      // Arrange
      when(mockAuthDataSource.getCurrentUser()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, null);
      verify(mockAuthDataSource.getCurrentUser()).called(1);
    });

    test('should return AuthenticationFailure when UnauthorizedException occurs', () async {
      // Arrange
      when(mockAuthDataSource.getCurrentUser()).thenThrow(UnauthorizedException(message: 'Unauthorized', statusCode: 401));

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isFailure, true);
      expect((result as Failure).error, isA<AuthenticationFailure>());
      verify(mockAuthDataSource.getCurrentUser()).called(1);
    });
  });
}
