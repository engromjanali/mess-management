import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';

class RequestAccountDeletionParams {
  final String password;
  final String? reason;

  const RequestAccountDeletionParams({required this.password, this.reason});
}

/// Schedules deletion of the signed-in account; returns when it takes effect.
@lazySingleton
class RequestAccountDeletionUseCase implements UseCase<DateTime, RequestAccountDeletionParams> {
  final AuthRepository _repository;

  RequestAccountDeletionUseCase(this._repository);

  @override
  ResultFuture<DateTime> call(RequestAccountDeletionParams params) => _repository.requestAccountDeletion(password: params.password, reason: params.reason);
}
