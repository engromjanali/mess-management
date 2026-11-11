import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';

/// Google login use case parameters
class GoogleLoginParams {
  final String idToken;

  const GoogleLoginParams({required this.idToken});
}

/// Exchanges a Google ID token for an authenticated app session
@lazySingleton
class GoogleLoginUseCase implements UseCase<UserEntity, GoogleLoginParams> {
  final AuthRepository _repository;

  GoogleLoginUseCase(this._repository);

  @override
  ResultFuture<UserEntity> call(GoogleLoginParams params) {
    return _repository.googleLogin(idToken: params.idToken);
  }
}
