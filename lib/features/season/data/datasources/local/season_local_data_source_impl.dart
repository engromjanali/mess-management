import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/features/season/data/datasources/interfaces/season_data_source.dart';
import 'package:clean_boilerplate/features/season/data/models/season_model.dart';
import 'package:clean_boilerplate/features/season/domain/entities/auto_create_season_entity.dart';

/// In-memory mock for the season feature.
///
/// Not bound: the app uses `SeasonRemoteDataSourceImpl`. Move its
/// `@LazySingleton(as: SeasonDataSource)` here to preview offline.
class SeasonLocalDataSourceImpl implements SeasonDataSource {
  static final DateTime _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  /// Session-mutable store, newest first.
  final List<SeasonModel> _seasons = [
    SeasonModel(id: '4', name: 'season-pwd', startDate: _today.subtract(const Duration(days: 3)), memberCount: 5),
    SeasonModel(id: '3', name: 'season-kqm', startDate: _today.subtract(const Duration(days: 12)), memberCount: 6),
    SeasonModel(id: '2', name: 'season-bza', startDate: _today.subtract(const Duration(days: 43)), endDate: _today.subtract(const Duration(days: 13)), memberCount: 6),
    SeasonModel(id: '1', name: 'season-rtx', startDate: _today.subtract(const Duration(days: 74)), endDate: _today.subtract(const Duration(days: 44)), disabled: true, memberCount: 4),
  ];
  String? _currentId = '3';
  AutoCreateSeasonEntity _autoCreate = const AutoCreateSeasonEntity(enabled: true);
  int _seq = 100;

  @override
  Future<SeasonOverviewModel> getSeasons() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return SeasonOverviewModel(seasons: List.of(_seasons), currentSeasonId: _currentId, autoCreate: _autoCreate);
  }

  @override
  Future<void> createSeason({required String name, required DateTime startDate, required String sourceSeasonId}) async {
    _seasons.insert(0, SeasonModel(id: '${_seq++}', name: name, startDate: startDate, memberCount: _find(sourceSeasonId).memberCount));
  }

  @override
  Future<void> updateSeason({required String id, required String name, required DateTime startDate, DateTime? endDate}) async {
    _replace(_find(id).copyWith(name: name, startDate: startDate, endDate: endDate, clearEndDate: endDate == null));
  }

  @override
  Future<void> endSeason(String id) async => _replace(_find(id).copyWith(endDate: _today));

  @override
  Future<void> setDisabled({required String id, required bool disabled}) async => _replace(_find(id).copyWith(disabled: disabled));

  @override
  Future<void> switchSeason(String id) async => _currentId = _find(id).id;

  @override
  Future<void> deleteSeason(String id) async {
    _seasons.removeWhere((season) => season.id == id);
    if (_currentId == id) _currentId = _seasons.where((season) => !season.disabled).firstOrNull?.id;
  }

  @override
  Future<void> updateAutoCreate({bool? enabled, int? day}) async => _autoCreate = _autoCreate.copyWith(enabled: enabled, day: day);

  SeasonModel _find(String id) => _seasons.firstWhere((season) => season.id == id, orElse: () => throw ServerException(message: 'Season not found in this mess.'));

  void _replace(SeasonModel updated) {
    final index = _seasons.indexWhere((season) => season.id == updated.id);
    _seasons[index] = updated;
  }
}
