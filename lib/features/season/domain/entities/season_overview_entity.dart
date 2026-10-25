import 'package:clean_boilerplate/features/season/domain/entities/auto_create_season_entity.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';

/// Everything the season management screen shows: every season of the mess
/// (newest first), the one the manager works in and the auto-create setting.
class SeasonOverviewEntity {
  const SeasonOverviewEntity({required this.seasons, required this.currentSeasonId, required this.autoCreate});

  final List<SeasonEntity> seasons;
  final String? currentSeasonId;
  final AutoCreateSeasonEntity autoCreate;

  SeasonEntity? get current => seasons.where((season) => season.id == currentSeasonId).firstOrNull;
}
