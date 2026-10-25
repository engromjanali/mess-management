import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_overview_entity.dart';
import 'package:clean_boilerplate/features/season/domain/repositories/season_repository.dart';

/// Loads every season, the one in use and the auto-create setting.
@lazySingleton
class GetSeasonsUseCase implements UseCase<SeasonOverviewEntity, NoParams> {
  final SeasonRepository _repository;
  GetSeasonsUseCase(this._repository);

  @override
  ResultFuture<SeasonOverviewEntity> call(NoParams params) => _repository.getSeasons();
}

/// Params for creating a season.
class CreateSeasonParams extends Equatable {
  final String name;
  final DateTime startDate;

  /// The season whose members (who haven't left) are copied.
  final String sourceSeasonId;

  const CreateSeasonParams({required this.name, required this.startDate, required this.sourceSeasonId});

  @override
  List<Object?> get props => [name, startDate, sourceSeasonId];
}

/// Creates a season; no other season ends and nobody switches.
@lazySingleton
class CreateSeasonUseCase implements UseCase<void, CreateSeasonParams> {
  final SeasonRepository _repository;
  CreateSeasonUseCase(this._repository);

  @override
  ResultVoid call(CreateSeasonParams params) => _repository.createSeason(name: params.name, startDate: params.startDate, sourceSeasonId: params.sourceSeasonId);
}

/// Params for editing a season; a null [endDate] reopens it.
class UpdateSeasonParams extends Equatable {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;

  const UpdateSeasonParams({required this.id, required this.name, required this.startDate, this.endDate});

  @override
  List<Object?> get props => [id, name, startDate, endDate];
}

/// Renames a season or moves its dates.
@lazySingleton
class UpdateSeasonUseCase implements UseCase<void, UpdateSeasonParams> {
  final SeasonRepository _repository;
  UpdateSeasonUseCase(this._repository);

  @override
  ResultVoid call(UpdateSeasonParams params) => _repository.updateSeason(id: params.id, name: params.name, startDate: params.startDate, endDate: params.endDate);
}

/// Ends a running season today.
@lazySingleton
class EndSeasonUseCase implements UseCase<void, String> {
  final SeasonRepository _repository;
  EndSeasonUseCase(this._repository);

  @override
  ResultVoid call(String id) => _repository.endSeason(id);
}

/// Params for disabling / enabling a season.
class SetSeasonDisabledParams extends Equatable {
  final String id;
  final bool disabled;

  const SetSeasonDisabledParams({required this.id, required this.disabled});

  @override
  List<Object?> get props => [id, disabled];
}

/// Disables or enables a season.
@lazySingleton
class SetSeasonDisabledUseCase implements UseCase<void, SetSeasonDisabledParams> {
  final SeasonRepository _repository;
  SetSeasonDisabledUseCase(this._repository);

  @override
  ResultVoid call(SetSeasonDisabledParams params) => _repository.setDisabled(id: params.id, disabled: params.disabled);
}

/// Makes a season the one the manager works in.
@lazySingleton
class SwitchSeasonUseCase implements UseCase<void, String> {
  final SeasonRepository _repository;
  SwitchSeasonUseCase(this._repository);

  @override
  ResultVoid call(String id) => _repository.switchSeason(id);
}

/// Deletes a season with all its meals, deposits and costs.
@lazySingleton
class DeleteSeasonUseCase implements UseCase<void, String> {
  final SeasonRepository _repository;
  DeleteSeasonUseCase(this._repository);

  @override
  ResultVoid call(String id) => _repository.deleteSeason(id);
}

/// Params for the auto-create setting; null fields stay unchanged.
class UpdateAutoCreateSeasonParams extends Equatable {
  final bool? enabled;

  /// 1–28, or 0 for the month's last day.
  final int? day;

  const UpdateAutoCreateSeasonParams({this.enabled, this.day});

  @override
  List<Object?> get props => [enabled, day];
}

/// Saves the auto-create setting.
@lazySingleton
class UpdateAutoCreateSeasonUseCase implements UseCase<void, UpdateAutoCreateSeasonParams> {
  final SeasonRepository _repository;
  UpdateAutoCreateSeasonUseCase(this._repository);

  @override
  ResultVoid call(UpdateAutoCreateSeasonParams params) => _repository.updateAutoCreate(enabled: params.enabled, day: params.day);
}
