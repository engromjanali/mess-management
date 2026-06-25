import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/fund/domain/entities/fund_entity.dart';
import 'package:clean_boilerplate/features/fund/domain/repositories/fund_repository.dart';

/// Loads every fund entry (all dates).
@lazySingleton
class GetAllFundsUseCase implements UseCase<List<FundEntity>, NoParams> {
  final FundRepository _repository;
  GetAllFundsUseCase(this._repository);

  @override
  ResultFuture<List<FundEntity>> call(NoParams params) =>
      _repository.getAllFunds();
}

/// Loads fund entries on a given day.
@lazySingleton
class GetFundsByDateUseCase implements UseCase<List<FundEntity>, DateTime> {
  final FundRepository _repository;
  GetFundsByDateUseCase(this._repository);

  @override
  ResultFuture<List<FundEntity>> call(DateTime date) =>
      _repository.getFundsByDate(date);
}

/// Params for a custom inclusive date range.
class FundRangeParams extends Equatable {
  final DateTime start;
  final DateTime end;

  const FundRangeParams({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

/// Loads fund entries within a date range.
@lazySingleton
class GetFundsInRangeUseCase
    implements UseCase<List<FundEntity>, FundRangeParams> {
  final FundRepository _repository;
  GetFundsInRangeUseCase(this._repository);

  @override
  ResultFuture<List<FundEntity>> call(FundRangeParams params) =>
      _repository.getFundsInRange(params.start, params.end);
}

/// Params for recording a fund entry.
class AddFundParams extends Equatable {
  final double amount;
  final DateTime date;
  final String? note;

  const AddFundParams({required this.amount, required this.date, this.note});

  @override
  List<Object?> get props => [amount, date, note];
}

/// Records a fund entry.
@lazySingleton
class AddFundUseCase implements UseCase<FundEntity, AddFundParams> {
  final FundRepository _repository;
  AddFundUseCase(this._repository);

  @override
  ResultFuture<FundEntity> call(AddFundParams params) => _repository.addFund(
        amount: params.amount,
        date: params.date,
        note: params.note,
      );
}

/// Params for editing an existing fund entry.
class UpdateFundParams extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  const UpdateFundParams({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [id, amount, date, note];
}

/// Edits an existing fund entry.
@lazySingleton
class UpdateFundUseCase implements UseCase<FundEntity, UpdateFundParams> {
  final FundRepository _repository;
  UpdateFundUseCase(this._repository);

  @override
  ResultFuture<FundEntity> call(UpdateFundParams params) =>
      _repository.updateFund(
        id: params.id,
        amount: params.amount,
        date: params.date,
        note: params.note,
      );
}

/// Removes a fund entry by id.
@lazySingleton
class DeleteFundUseCase implements UseCase<void, String> {
  final FundRepository _repository;
  DeleteFundUseCase(this._repository);

  @override
  ResultVoid call(String id) => _repository.deleteFund(id);
}
