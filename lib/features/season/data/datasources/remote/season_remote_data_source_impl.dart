import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/season/data/datasources/interfaces/season_data_source.dart';
import 'package:clean_boilerplate/features/season/data/models/season_model.dart';

/// Season management APIs under `/api/v1/admin/seasons` (manager / acting manager).
@LazySingleton(as: SeasonDataSource)
class SeasonRemoteDataSourceImpl implements SeasonDataSource {
  final ApiClient _apiClient;

  SeasonRemoteDataSourceImpl(this._apiClient);

  static final DateFormat _day = DateFormat('yyyy-MM-dd');

  @override
  Future<SeasonOverviewModel> getSeasons() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.adminSeasonsEndpoint);
    return SeasonOverviewModel.fromJson(response.data!);
  }

  @override
  Future<void> createSeason({required String name, required DateTime startDate, required String sourceSeasonId}) async {
    await _apiClient.post<Map<String, dynamic>>(
      AppConstants.adminSeasonsEndpoint,
      data: {'name': name, 'start_date': _day.format(startDate), 'source_season_id': int.parse(sourceSeasonId)},
    );
  }

  @override
  Future<void> updateSeason({required String id, required String name, required DateTime startDate, DateTime? endDate}) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.adminSeasonsEndpoint}/$id',
      data: {'name': name, 'start_date': _day.format(startDate), 'end_date': endDate == null ? null : _day.format(endDate)},
    );
  }

  @override
  Future<void> endSeason(String id) async {
    await _apiClient.post<Map<String, dynamic>>('${AppConstants.adminSeasonsEndpoint}/$id/end');
  }

  @override
  Future<void> setDisabled({required String id, required bool disabled}) async {
    await _apiClient.post<Map<String, dynamic>>('${AppConstants.adminSeasonsEndpoint}/$id/${disabled ? 'disable' : 'enable'}');
  }

  @override
  Future<void> switchSeason(String id) async {
    await _apiClient.post<Map<String, dynamic>>('${AppConstants.adminSeasonsEndpoint}/$id/switch');
  }

  @override
  Future<void> deleteSeason(String id) async {
    await _apiClient.delete<Map<String, dynamic>>('${AppConstants.adminSeasonsEndpoint}/$id');
  }

  @override
  Future<void> updateAutoCreate({bool? enabled, int? day}) async {
    await _apiClient.put<Map<String, dynamic>>(AppConstants.adminSeasonAutoCreateEndpoint, data: {'enabled': ?enabled, 'day': ?day});
  }
}
