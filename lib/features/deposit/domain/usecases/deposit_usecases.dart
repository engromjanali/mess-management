import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';
import 'package:clean_boilerplate/features/deposit/domain/repositories/deposit_repository.dart';

/// Loads the member roster (for the add/edit picker and the by-member filter).
@lazySingleton
class GetDepositMembersUseCase implements UseCase<List<DepositMemberEntity>, NoParams> {
  final DepositRepository _repository;
  GetDepositMembersUseCase(this._repository);

  @override
  ResultFuture<List<DepositMemberEntity>> call(NoParams params) => _repository.getMembers();
}

/// Loads every deposit (all members, all dates).
@lazySingleton
class GetAllDepositsUseCase implements UseCase<List<DepositEntity>, NoParams> {
  final DepositRepository _repository;
  GetAllDepositsUseCase(this._repository);

  @override
  ResultFuture<List<DepositEntity>> call(NoParams params) => _repository.getAllDeposits();
}

/// Loads every deposit for a single member.
@lazySingleton
class GetMemberDepositsUseCase implements UseCase<List<DepositEntity>, String> {
  final DepositRepository _repository;
  GetMemberDepositsUseCase(this._repository);

  @override
  ResultFuture<List<DepositEntity>> call(String memberId) => _repository.getMemberDeposits(memberId);
}

/// Params for a custom inclusive date range.
class DepositRangeParams extends Equatable {
  final DateTime start;
  final DateTime end;

  const DepositRangeParams({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

/// Loads every member's deposits within a date range.
@lazySingleton
class GetDepositsInRangeUseCase implements UseCase<List<DepositEntity>, DepositRangeParams> {
  final DepositRepository _repository;
  GetDepositsInRangeUseCase(this._repository);

  @override
  ResultFuture<List<DepositEntity>> call(DepositRangeParams params) => _repository.getDepositsInRange(params.start, params.end);
}

/// Loads every member's deposits on a given day.
@lazySingleton
class GetDepositsByDateUseCase implements UseCase<List<DepositEntity>, DateTime> {
  final DepositRepository _repository;
  GetDepositsByDateUseCase(this._repository);

  @override
  ResultFuture<List<DepositEntity>> call(DateTime date) => _repository.getDepositsByDate(date);
}

/// Loads the signed-in user's own deposits.
@lazySingleton
class GetMyDepositsUseCase implements UseCase<List<DepositEntity>, NoParams> {
  final DepositRepository _repository;
  GetMyDepositsUseCase(this._repository);

  @override
  ResultFuture<List<DepositEntity>> call(NoParams params) => _repository.getMyDeposits();
}

/// Params for recording a deposit against a single member.
class AddDepositParams extends Equatable {
  final String memberId;
  final double amount;
  final DateTime date;
  final String? note;

  const AddDepositParams({required this.memberId, required this.amount, required this.date, this.note});

  @override
  List<Object?> get props => [memberId, amount, date, note];
}

/// Records a deposit for one member at a time.
@lazySingleton
class AddDepositUseCase implements UseCase<DepositEntity, AddDepositParams> {
  final DepositRepository _repository;
  AddDepositUseCase(this._repository);

  @override
  ResultFuture<DepositEntity> call(AddDepositParams params) => _repository.addDeposit(memberId: params.memberId, amount: params.amount, date: params.date, note: params.note);
}

/// Params for editing an existing deposit.
class UpdateDepositParams extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  const UpdateDepositParams({required this.id, required this.amount, required this.date, this.note});

  @override
  List<Object?> get props => [id, amount, date, note];
}

/// Edits an existing deposit.
@lazySingleton
class UpdateDepositUseCase implements UseCase<DepositEntity, UpdateDepositParams> {
  final DepositRepository _repository;
  UpdateDepositUseCase(this._repository);

  @override
  ResultFuture<DepositEntity> call(UpdateDepositParams params) => _repository.updateDeposit(id: params.id, amount: params.amount, date: params.date, note: params.note);
}

/// Removes a deposit by id.
@lazySingleton
class DeleteDepositUseCase implements UseCase<void, String> {
  final DepositRepository _repository;
  DeleteDepositUseCase(this._repository);

  @override
  ResultVoid call(String id) => _repository.deleteDeposit(id);
}
