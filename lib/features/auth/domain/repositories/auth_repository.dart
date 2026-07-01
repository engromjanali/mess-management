import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';

/// Auth repository interface (abstraction in domain layer)
abstract class AuthRepository {
  ResultFuture<UserEntity> login({required String email, required String password});

  ResultFuture<UserEntity> register({required String fullName, required String email, required String password, String? phone});

  ResultFuture<void> forgotPassword({required String email});

  ResultFuture<void> resetPassword({required String email, required String otp, required String password});

  ResultFuture<void> logout();

  ResultFuture<UserEntity?> getCurrentUser();
}
