import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';

/// Cancels a scheduled account deletion: the account stays.
@lazySingleton
class CancelAccountDeletionUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;

  CancelAccountDeletionUseCase(this._repository);

  @override
  ResultFuture<void> call(NoParams params) => _repository.cancelAccountDeletion();
}
