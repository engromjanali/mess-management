import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileParams {
  final String fullName;
  final String email;
  final String phone;
  final String? address;
  final List<int>? photoBytes;
  final String? photoName;

  const UpdateProfileParams({required this.fullName, required this.email, required this.phone, this.address, this.photoBytes, this.photoName});
}

/// Update profile use case
@lazySingleton
class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  @override
  ResultFuture<UserEntity> call(UpdateProfileParams params) {
    return _repository.updateProfile(fullName: params.fullName, email: params.email, phone: params.phone, address: params.address, photoBytes: params.photoBytes, photoName: params.photoName);
  }
}
