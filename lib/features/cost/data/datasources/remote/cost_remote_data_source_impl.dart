import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/data/models/cost_model.dart';
import 'package:clean_boilerplate/features/cost/data/datasources/interfaces/cost_data_source.dart';

/// Cost data source backed by the Django API (active season only).
///
/// Every member (the manager included) reads the season's costs through the
/// user endpoint; add / edit / delete go through the manager-only admin
/// endpoint. Member ids are membership ids of the current season.
@LazySingleton(as: CostDataSource)
class CostRemoteDataSourceImpl implements CostDataSource {
  final ApiClient _apiClient;

  CostRemoteDataSourceImpl(this._apiClient);

  static final DateFormat _day = DateFormat('yyyy-MM-dd');
  static final DateFormat _time = DateFormat('HH:mm');

  @override
  Future<List<CostMemberModel>> getMembers() async {
    final response = await _apiClient.get<List<dynamic>>(AppConstants.managerMembersEndpoint);
    return (response.data ?? []).map((item) {
      final json = item as Map<String, dynamic>;
      return CostMemberModel(id: '${json['membership_id']}', name: json['name'] as String? ?? '');
    }).toList();
  }

  @override
  Future<CostSeasonModel> getCosts() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.costsEndpoint);
    final data = response.data ?? const {};
    final season = data['season'] as Map<String, dynamic>?;
    return CostSeasonModel(
      seasonName: season?['name'] as String? ?? '',
      costs: ((data['data'] as List<dynamic>?) ?? const []).map((item) => _parse(item as Map<String, dynamic>)).toList(),
    );
  }

  @override
  Future<CostModel> addCost({required String personId, required DateTime date, required List<CostItemEntity> items}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(AppConstants.adminCostsEndpoint, data: _body(personId, date, items));
    return _parse(response.data!);
  }

  @override
  Future<CostModel> updateCost({required String id, required String personId, required DateTime date, required List<CostItemEntity> items}) async {
    final response = await _apiClient.patch<Map<String, dynamic>>('${AppConstants.adminCostsEndpoint}/$id', data: _body(personId, date, items));
    return _parse(response.data!);
  }

  @override
  Future<void> deleteCost(String id) async {
    await _apiClient.delete<void>('${AppConstants.adminCostsEndpoint}/$id');
  }

  Map<String, dynamic> _body(String personId, DateTime date, List<CostItemEntity> items) => {
    'member_id': int.parse(personId),
    'date': _day.format(date),
    'time': _time.format(date),
    'items': [for (final i in items) {'product': i.product, 'price': i.price.toStringAsFixed(2)}],
  };

  /// `date` (yyyy-MM-dd) and the optional wall-clock `time` (HH:mm) combine
  /// into one local [DateTime].
  CostModel _parse(Map<String, dynamic> json) {
    final day = DateTime.parse(json['date'] as String);
    final time = (json['time'] as String?)?.split(':');
    return CostModel(
      id: '${json['id']}',
      personId: '${json['member_id']}',
      personName: json['member_name'] as String? ?? '',
      date: time == null ? day : DateTime(day.year, day.month, day.day, int.parse(time[0]), int.parse(time[1])),
      items: ((json['items'] as List<dynamic>?) ?? const []).map((item) {
        final i = item as Map<String, dynamic>;
        return CostItemModel(product: i['product'] as String? ?? '', price: (i['price'] as num).toDouble());
      }).toList(),
    );
  }
}
