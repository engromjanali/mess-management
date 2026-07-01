import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_boilerplate/features/auth/data/datasources/interfaces/auth_data_source.dart';

/// Auth repository implementation (concrete class in data layer)
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  ResultFuture<UserEntity> login({required String email, required String password}) async {
    try {
      final userModel = await _dataSource.login(email: email, password: password);
      return Result.success(data: userModel.toEntity());
    } on UnauthorizedException catch (e) {
      return Result.failure(
        error: AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NoInternetException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on RequestTimeoutException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on NetworkException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Result.failure(
        error: ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  ResultFuture<void> logout() async {
    try {
      await _dataSource.logout();
      return Result.success(data: null);
    } on UnauthorizedException catch (e) {
      return Result.failure(
        error: AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NoInternetException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on RequestTimeoutException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on NetworkException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Result.failure(
        error: ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  ResultFuture<UserEntity?> getCurrentUser() async {
    try {
      final userModel = await _dataSource.getCurrentUser();
      return Result.success(data: userModel?.toEntity());
    } on UnauthorizedException catch (e) {
      return Result.failure(
        error: AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on NoInternetException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on RequestTimeoutException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on NetworkException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Result.failure(
        error: ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  ResultFuture<UserEntity> register({required String fullName, required String email, required String password, String? phone}) {
    return _guard(() async {
      final userModel = await _dataSource.register(fullName: fullName, email: email, password: password, phone: phone);
      return userModel.toEntity();
    });
  }

  @override
  ResultFuture<void> forgotPassword({required String email}) {
    return _guard(() => _dataSource.forgotPassword(email: email));
  }

  @override
  ResultFuture<void> resetPassword({required String email, required String otp, required String password}) {
    return _guard(() => _dataSource.resetPassword(email: email, otp: otp, password: password));
  }

  /// Runs [action], mapping data-layer exceptions onto the failure hierarchy.
  ResultFuture<T> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(data: await action());
    } on UnauthorizedException catch (e) {
      return Result.failure(error: AuthenticationFailure(message: e.message, statusCode: e.statusCode));
    } on NoInternetException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on RequestTimeoutException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on NetworkException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Result.failure(error: ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}
