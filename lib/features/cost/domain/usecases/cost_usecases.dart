import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/domain/repositories/cost_repository.dart';

/// Loads the member roster (for the entry person picker).
@lazySingleton
class GetCostMembersUseCase implements UseCase<List<CostMemberEntity>, NoParams> {
  final CostRepository _repository;
  GetCostMembersUseCase(this._repository);

  @override
  ResultFuture<List<CostMemberEntity>> call(NoParams params) => _repository.getMembers();
}

/// Loads every bazar/cost entry.
@lazySingleton
class GetCostsUseCase implements UseCase<List<CostEntity>, NoParams> {
  final CostRepository _repository;
  GetCostsUseCase(this._repository);

  @override
  ResultFuture<List<CostEntity>> call(NoParams params) => _repository.getCosts();
}

/// Params for recording a bazar/cost entry.
class AddCostParams extends Equatable {
  final String personId;
  final DateTime date;
  final List<CostItemEntity> items;

  const AddCostParams({required this.personId, required this.date, required this.items});

  @override
  List<Object?> get props => [personId, date, items];
}

/// Records a bazar/cost entry.
@lazySingleton
class AddCostUseCase implements UseCase<CostEntity, AddCostParams> {
  final CostRepository _repository;
  AddCostUseCase(this._repository);

  @override
  ResultFuture<CostEntity> call(AddCostParams params) => _repository.addCost(personId: params.personId, date: params.date, items: params.items);
}

/// Params for editing an existing bazar/cost entry.
class UpdateCostParams extends Equatable {
  final String id;
  final String personId;
  final DateTime date;
  final List<CostItemEntity> items;

  const UpdateCostParams({required this.id, required this.personId, required this.date, required this.items});

  @override
  List<Object?> get props => [id, personId, date, items];
}

/// Edits an existing bazar/cost entry.
@lazySingleton
class UpdateCostUseCase implements UseCase<CostEntity, UpdateCostParams> {
  final CostRepository _repository;
  UpdateCostUseCase(this._repository);

  @override
  ResultFuture<CostEntity> call(UpdateCostParams params) => _repository.updateCost(id: params.id, personId: params.personId, date: params.date, items: params.items);
}

/// Removes a bazar/cost entry by id.
@lazySingleton
class DeleteCostUseCase implements UseCase<void, String> {
  final CostRepository _repository;
  DeleteCostUseCase(this._repository);

  @override
  ResultVoid call(String id) => _repository.deleteCost(id);
}
