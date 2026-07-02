import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/error_handler.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_boilerplate/features/auth/data/datasources/interfaces/auth_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  ResultFuture<UserEntity> login({required String email, required String password}) =>
      guardResult(() async => (await _dataSource.login(email: email, password: password)).toEntity());

  @override
  ResultFuture<void> logout() => guardResult(() => _dataSource.logout());

  @override
  ResultFuture<UserEntity?> getCurrentUser() =>
      guardResult(() async => (await _dataSource.getCurrentUser())?.toEntity());

  @override
  ResultFuture<UserEntity> register({required String fullName, required String email, required String password, String? phone}) =>
      guardResult(() async => (await _dataSource.register(fullName: fullName, email: email, password: password, phone: phone)).toEntity());

  @override
  ResultFuture<void> forgotPassword({required String email}) =>
      guardResult(() => _dataSource.forgotPassword(email: email));

  @override
  ResultFuture<void> resetPassword({required String email, required String otp, required String password}) =>
      guardResult(() => _dataSource.resetPassword(email: email, otp: otp, password: password));
}
