import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';

/// Cancels a scheduled account deletion: the account stays.
@lazySingleton
class CancelAccountDeletionUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;

  CancelAccountDeletionUseCase(this._repository);

  @override
  ResultFuture<void> call(NoParams params) => _repository.cancelAccountDeletion();
}
