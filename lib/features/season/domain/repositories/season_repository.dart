import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_overview_entity.dart';

/// Season repository contract (abstraction in the domain layer).
abstract class SeasonRepository {
  /// Every season, the one the manager works in and the auto-create setting.
  ResultFuture<SeasonOverviewEntity> getSeasons();

  /// Creates a season with [sourceSeasonId]'s members who haven't left.
  ResultVoid createSeason({required String name, required DateTime startDate, required String sourceSeasonId});

  /// Renames / moves the dates of a season; a null [endDate] reopens it.
  ResultVoid updateSeason({required String id, required String name, required DateTime startDate, DateTime? endDate});

  /// Ends a running season today.
  ResultVoid endSeason(String id);

  ResultVoid setDisabled({required String id, required bool disabled});

  /// Makes [id] the season the manager works in.
  ResultVoid switchSeason(String id);

  /// Deletes a season with all its meals, deposits and costs.
  ResultVoid deleteSeason(String id);

  /// Saves the auto-create setting (day 0 = the month's last day).
  ResultVoid updateAutoCreate({bool? enabled, int? day});
}
