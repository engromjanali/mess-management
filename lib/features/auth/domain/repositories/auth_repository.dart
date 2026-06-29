import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';

/// Auth repository interface (abstraction in domain layer)
abstract class AuthRepository {
  ResultFuture<UserEntity> login({required String email, required String password});

  ResultFuture<void> logout();

  ResultFuture<UserEntity?> getCurrentUser();
}
