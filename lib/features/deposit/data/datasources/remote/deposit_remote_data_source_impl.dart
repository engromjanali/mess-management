import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/deposit/data/models/deposit_model.dart';
import 'package:clean_boilerplate/features/deposit/data/datasources/interfaces/deposit_data_source.dart';

/// Deposit data source backed by the Django API (active season only).
///
/// Member ids are membership ids. A positive amount is a credit, a negative
/// amount a debit. The manager is also a member, so "my deposits" works for them too.
@LazySingleton(as: DepositDataSource)
class DepositRemoteDataSourceImpl implements DepositDataSource {
  final ApiClient _apiClient;

  DepositRemoteDataSourceImpl(this._apiClient);

  static final DateFormat _day = DateFormat('yyyy-MM-dd');

  @override
  Future<List<DepositMemberModel>> getMembers() async {
    final response = await _apiClient.get<List<dynamic>>(AppConstants.managerMembersEndpoint);
    return (response.data ?? []).map((item) {
      final json = item as Map<String, dynamic>;
      return DepositMemberModel(id: '${json['membership_id']}', name: json['name'] as String? ?? '');
    }).toList();
  }

  @override
  Future<List<DepositModel>> getAllDeposits() => _adminList(const {});

  @override
  Future<List<DepositModel>> getMemberDeposits(String memberId) => _adminList({'member_id': memberId});

  @override
  Future<List<DepositModel>> getDepositsByDate(DateTime date) => _adminList({'date': _day.format(date)});

  @override
  Future<List<DepositModel>> getDepositsInRange(DateTime start, DateTime end) => _adminList({'start': _day.format(start), 'end': _day.format(end)});

  @override
  Future<List<DepositModel>> getMyDeposits() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.myDepositsEndpoint);
    return _parseList(response.data);
  }

  @override
  Future<DepositModel> addDeposit({required String memberId, required double amount, required DateTime date, String? note}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.adminDepositsEndpoint,
      data: {'member_id': memberId, 'amount': amount.toStringAsFixed(2), 'date': _day.format(date), 'note': note ?? ''},
    );
    return _parse(response.data!);
  }

  @override
  Future<DepositModel> updateDeposit({required String id, required double amount, required DateTime date, String? note}) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.adminDepositsEndpoint}/$id',
      data: {'amount': amount.toStringAsFixed(2), 'date': _day.format(date), 'note': note ?? ''},
    );
    return _parse(response.data!);
  }

  @override
  Future<void> deleteDeposit(String id) async {
    await _apiClient.delete<void>('${AppConstants.adminDepositsEndpoint}/$id');
  }

  Future<List<DepositModel>> _adminList(Map<String, dynamic> query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.adminDepositsEndpoint, queryParameters: query.isEmpty ? null : query);
    return _parseList(response.data);
  }

  List<DepositModel> _parseList(Map<String, dynamic>? body) => ((body?['data'] as List<dynamic>?) ?? const []).map((item) => _parse(item as Map<String, dynamic>)).toList();

  DepositModel _parse(Map<String, dynamic> json) {
    final note = json['note'] as String?;
    return DepositModel(
      id: '${json['id']}',
      memberId: '${json['member_id']}',
      memberName: json['member_name'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: (note == null || note.isEmpty) ? null : note,
    );
  }
}
