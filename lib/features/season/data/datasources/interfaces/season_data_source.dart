import 'package:clean_boilerplate/features/season/data/models/season_model.dart';

/// Contract for any source that can provide & change a mess's seasons.
abstract class SeasonDataSource {
  /// Every season, the one the manager works in and the auto-create setting.
  Future<SeasonOverviewModel> getSeasons();

  /// Creates a season whose members are copied from [sourceSeasonId] (members
  /// who left are skipped). No season ends and nobody switches.
  Future<void> createSeason({required String name, required DateTime startDate, required String sourceSeasonId});

  /// Renames / moves the dates of a season; a null [endDate] reopens it.
  Future<void> updateSeason({required String id, required String name, required DateTime startDate, DateTime? endDate});

  /// Ends a running season today.
  Future<void> endSeason(String id);

  Future<void> setDisabled({required String id, required bool disabled});

  /// Makes [id] the season the manager works in.
  Future<void> switchSeason(String id);

  /// Deletes a season with all its meals, deposits and costs.
  Future<void> deleteSeason(String id);

  /// Saves the auto-create setting (day 0 = the month's last day).
  Future<void> updateAutoCreate({bool? enabled, int? day});
}
