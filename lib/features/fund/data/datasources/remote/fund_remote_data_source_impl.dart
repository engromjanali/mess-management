import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/fund/data/models/fund_model.dart';
import 'package:clean_boilerplate/features/fund/data/datasources/interfaces/fund_data_source.dart';

/// Fund data source backed by the Django API (active season only).
///
/// Every member (the manager included) reads the shared fund through the user
/// endpoint; add / edit / delete go through the manager-only admin endpoint.
/// A positive amount is a credit, a negative amount a debit.
@LazySingleton(as: FundDataSource)
class FundRemoteDataSourceImpl implements FundDataSource {
  final ApiClient _apiClient;

  FundRemoteDataSourceImpl(this._apiClient);

  static final DateFormat _day = DateFormat('yyyy-MM-dd');

  @override
  Future<List<FundModel>> getAllFunds() => _list(const {});

  @override
  Future<List<FundModel>> getFundsByDate(DateTime date) => _list({'date': _day.format(date)});

  @override
  Future<List<FundModel>> getFundsInRange(DateTime start, DateTime end) => _list({'start_date': _day.format(start), 'end_date': _day.format(end)});

  @override
  Future<FundModel> addFund({required double amount, required DateTime date, String? note}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.adminFundsEndpoint,
      data: {'amount': amount.toStringAsFixed(2), 'date': _day.format(date), 'note': note ?? ''},
    );
    return _parse(response.data!);
  }

  @override
  Future<FundModel> updateFund({required String id, required double amount, required DateTime date, String? note}) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.adminFundsEndpoint}/$id',
      data: {'amount': amount.toStringAsFixed(2), 'date': _day.format(date), 'note': note ?? ''},
    );
    return _parse(response.data!);
  }

  @override
  Future<void> deleteFund(String id) async {
    await _apiClient.delete<void>('${AppConstants.adminFundsEndpoint}/$id');
  }

  Future<List<FundModel>> _list(Map<String, dynamic> query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.fundsEndpoint, queryParameters: query.isEmpty ? null : query);
    return ((response.data?['data'] as List<dynamic>?) ?? const []).map((item) => _parse(item as Map<String, dynamic>)).toList();
  }

  FundModel _parse(Map<String, dynamic> json) {
    final note = json['note'] as String?;
    return FundModel(
      id: '${json['id']}',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: (note == null || note.isEmpty) ? null : note,
    );
  }
}
