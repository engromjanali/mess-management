import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/membership_status_entity.dart';

class MembershipApiService {
  const MembershipApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<MembershipStatusEntity> getStatus() async {
    final statusResponse = await _apiClient.get<Map<String, dynamic>>(AppConstants.membershipStatusEndpoint);
    final status = statusResponse.data!;
    return MembershipStatusEntity(
      current: status['current'] == null ? null : _membership(status['current'] as Map<String, dynamic>),
      history: (status['history'] as List<dynamic>? ?? []).map((item) => _membership(item as Map<String, dynamic>)).toList(),
      pendingRequests: (status['pending_requests'] as List<dynamic>? ?? []).map((item) {
        final json = item as Map<String, dynamic>;
        return JoinRequestSummaryEntity(id: json['id'] as int, messId: json['mess_id'] as int, messName: json['mess_name'] as String);
      }).toList(),
      invites: (status['invites'] as List<dynamic>? ?? []).map((item) {
        final json = item as Map<String, dynamic>;
        final status = json['status'] as String? ?? 'pending';
        return InviteSummaryEntity(id: json['id'] as int, messId: json['mess_id'] as int, messName: json['mess_name'] as String, inviteCode: json['invite_code'] as String, status: status.isEmpty ? 'pending' : status);
      }).toList(),
      availableMesses: const [],
    );
  }

  Future<MessPageEntity> getAvailableMesses({required int page, required int limit, String search = ''}) async {
    final response = await _apiClient.get<dynamic>(AppConstants.availableMessesEndpoint, queryParameters: {'page': page, 'per_page': limit, if (search.trim().isNotEmpty) 'search': search.trim()});
    final body = response.data;
    final pagination = body is Map<String, dynamic> && body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body;
    final data = pagination is Map<String, dynamic> ? pagination['data'] ?? pagination['results'] ?? <dynamic>[] : pagination;
    final items = data is List<dynamic> ? data : <dynamic>[];
    final meta = pagination is Map<String, dynamic> && pagination['meta'] is Map<String, dynamic> ? pagination['meta'] as Map<String, dynamic> : pagination is Map<String, dynamic> ? pagination : <String, dynamic>{};
    final messes = items.map((item) {
      final json = item as Map<String, dynamic>;
      return MessSummaryEntity(id: json['id'] as int, name: json['name'] as String, address: json['address'] as String? ?? '');
    }).toList();
    final total = (meta['total'] as num?)?.toInt() ?? (meta['count'] as num?)?.toInt() ?? messes.length;
    return MessPageEntity(
      messes: messes,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? (meta['count'] != null ? (total + limit - 1) ~/ limit : messes.length < limit ? page : page + 1),
      total: total,
    );
  }

  Future<void> joinInvite(String code) async {
    await _apiClient.post<void>(AppConstants.joinInviteEndpoint, data: {'invite_code': code});
  }

  Future<void> requestJoin(int messId) async {
    await _apiClient.post<void>(AppConstants.joinRequestEndpoint, data: {'mess_id': messId});
  }

  Future<void> createMess({required String name, required String address, required String seasonName}) async {
    await _apiClient.post<void>(AppConstants.createMessEndpoint, data: {'name': name, 'address': address, 'season_name': seasonName});
  }

  Future<Map<String, dynamic>> findMember(String query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.memberLookupEndpoint, queryParameters: {'query': query});
    return response.data!;
  }

  Future<Map<String, dynamic>> createInvite(String userId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(AppConstants.createInviteEndpoint, data: {'user_id': userId});
    return response.data!;
  }

  Future<List<Map<String, dynamic>>> getManagerInvites() async {
    final response = await _apiClient.get<List<dynamic>>(AppConstants.createInviteEndpoint);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> revokeInvite(int inviteId) async {
    await _apiClient.delete<void>(AppConstants.createInviteEndpoint, data: {'invite_id': inviteId});
  }

  Future<List<Map<String, dynamic>>> getManagerRequests() async {
    final response = await _apiClient.get<List<dynamic>>(AppConstants.managerJoinRequestsEndpoint);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getManagerMembers() async {
    final response = await _apiClient.get<List<dynamic>>(AppConstants.managerMembersEndpoint);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> decideRequest(int requestId, bool accept) async {
    await _apiClient.post<void>(AppConstants.joinRequestDecisionEndpoint, data: {'request_id': requestId, 'decision': accept ? 'accepted' : 'rejected'});
  }

  Future<Map<String, dynamic>> getMessDetails() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.messDetailsEndpoint);
    return response.data!;
  }

  Future<void> updateMess({required String name, required String address, required String email, required String phone}) async {
    await _apiClient.patch<void>(AppConstants.messDetailsEndpoint, data: {'name': name, 'address': address, 'email': email, 'phone': phone});
  }

  Future<void> transferMessLeadership({required String userId, required String role}) async {
    await _apiClient.post<void>(AppConstants.messLeadershipEndpoint, data: {'user_id': userId, 'role': role});
  }

  Future<void> leaveMess() async {
    await _apiClient.post<void>(AppConstants.leaveMessEndpoint);
  }

  MembershipSummaryEntity _membership(Map<String, dynamic> json) => MembershipSummaryEntity(
    membershipId: json['membership_id'] as int,
    messId: json['mess_id'] as int,
    messName: json['mess_name'] as String,
    seasonName: json['season_name'] as String,
    role: json['role'] as String? ?? 'member',
    status: json['status'] as String?,
    totalDeposit: (json['total_deposit'] as num?)?.toDouble() ?? 0,
    totalMeal: (json['total_meal'] as num?)?.toDouble() ?? 0,
  );
}
