import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/mess_details_entity.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/membership_status_entity.dart';

class MembershipApiService {
  const MembershipApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<MembershipStatusEntity> getStatus() async {
    final statusResponse = await _apiClient.get<Map<String, dynamic>>(AppConstants.membershipStatusEndpoint);
    final status = statusResponse.data!;
    return MembershipStatusEntity(
      current: status['current'] == null ? null : _membership(status['current'] as Map<String, dynamic>),
      memberships: (status['memberships'] as List<dynamic>? ?? []).map((item) => _membership(item as Map<String, dynamic>)).toList(),
      history: (status['history'] as List<dynamic>? ?? []).map((item) => _membership(item as Map<String, dynamic>)).toList(),
      pendingRequests: (status['pending_requests'] as List<dynamic>? ?? []).map((item) {
        final json = item as Map<String, dynamic>;
        return JoinRequestSummaryEntity(id: json['id'] as int, messId: json['mess_id'] as int, messName: json['mess_name'] as String);
      }).toList(),
      invites: (status['invites'] as List<dynamic>? ?? []).map((item) {
        final json = item as Map<String, dynamic>;
        final status = json['status'] as String? ?? 'pending';
        return InviteSummaryEntity(
          id: json['id'] as int,
          messId: json['mess_id'] as int,
          messName: json['mess_name'] as String,
          inviteCode: json['invite_code'] as String,
          status: status.isEmpty ? 'pending' : status,
        );
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
    final meta = pagination is Map<String, dynamic> && pagination['meta'] is Map<String, dynamic>
        ? pagination['meta'] as Map<String, dynamic>
        : pagination is Map<String, dynamic>
        ? pagination
        : <String, dynamic>{};
    final messes = items.map((item) {
      final json = item as Map<String, dynamic>;
      return MessSummaryEntity(id: json['id'] as int, name: json['name'] as String, address: json['address'] as String? ?? '');
    }).toList();
    final total = (meta['total'] as num?)?.toInt() ?? (meta['count'] as num?)?.toInt() ?? messes.length;
    return MessPageEntity(
      messes: messes,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage:
          (meta['last_page'] as num?)?.toInt() ??
          (meta['count'] != null
              ? (total + limit - 1) ~/ limit
              : messes.length < limit
              ? page
              : page + 1),
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

  /// Active members of the current season; with [includeDisabled] also the
  /// members a manager disabled (each has a `disabled` flag).
  Future<List<Map<String, dynamic>>> getManagerMembers({bool includeDisabled = false}) async {
    final response = await _apiClient.get<List<dynamic>>(AppConstants.managerMembersEndpoint, queryParameters: includeDisabled ? {'include_disabled': true} : null);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Turns a member off: they can't open the mess until enabled again.
  Future<void> disableMember(int membershipId) => _memberAction(membershipId, 'disable');

  Future<void> enableMember(int membershipId) => _memberAction(membershipId, 'enable');

  /// Primary manager only; replaces any current acting manager.
  Future<void> makeActingManager(int membershipId) => _memberAction(membershipId, 'acting-manager');

  /// Primary manager only.
  Future<void> removeActingManager(int membershipId) async {
    await _apiClient.delete<void>('${AppConstants.managerMembersEndpoint}/$membershipId/acting-manager');
  }

  /// Primary manager only: the member becomes the primary manager and the
  /// caller a regular member.
  Future<void> transferOwnership(int membershipId) => _memberAction(membershipId, 'transfer-ownership');

  Future<void> decideRequest(int requestId, bool accept) async {
    await _apiClient.post<void>(AppConstants.joinRequestDecisionEndpoint, data: {'request_id': requestId, 'decision': accept ? 'accepted' : 'rejected'});
  }

  /// The signed-in user's current mess and its active season.
  Future<MessDetailsEntity> getMessDetails() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.messDetailsEndpoint);
    final json = response.data!;
    final season = json['season'] as Map<String, dynamic>;
    final stats = json['stats'] as Map<String, dynamic>;
    final permissions = json['permissions'] as Map<String, dynamic>? ?? const {};
    return MessDetailsEntity(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      season: MessSeasonInfoEntity(
        id: season['id'] as int,
        name: season['name'] as String? ?? '',
        startDate: DateTime.parse(season['start_date'] as String),
        endDate: season['end_date'] == null ? null : DateTime.parse(season['end_date'] as String),
      ),
      myRole: json['my_role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String).toLocal(),
      manager: _person(json['manager']),
      actingManager: _person(json['acting_manager']),
      members: (json['members'] as List<dynamic>? ?? []).map((item) {
        final member = item as Map<String, dynamic>;
        return MessMemberEntity(
          membershipId: member['membership_id'] as int,
          userId: member['user_id'] as int,
          name: member['name'] as String? ?? '',
          role: member['role'] as String? ?? 'member',
          joinedAt: DateTime.parse(member['joined_at'] as String).toLocal(),
        );
      }).toList(),
      stats: MessStatsEntity(
        members: (stats['members'] as num?)?.toInt() ?? 0,
        totalMeals: (stats['total_meals'] as num?)?.toDouble() ?? 0,
        mealRate: (stats['meal_rate'] as num?)?.toDouble() ?? 0,
        totalCost: (stats['total_cost'] as num?)?.toDouble() ?? 0,
        totalDeposit: (stats['total_deposit'] as num?)?.toDouble() ?? 0,
        fundBalance: (stats['fund_balance'] as num?)?.toDouble() ?? 0,
      ),
      canEdit: permissions['can_edit'] as bool? ?? false,
      canTransfer: permissions['can_transfer'] as bool? ?? false,
      canLeave: permissions['can_leave'] as bool? ?? false,
    );
  }

  Future<void> updateMess({required String name, required String address, required String email, required String phone}) async {
    await _apiClient.patch<void>(AppConstants.messUpdateEndpoint, data: {'name': name, 'address': address, 'email': email, 'phone': phone});
  }

  Future<void> leaveMess() async {
    await _apiClient.post<void>(AppConstants.leaveMessEndpoint);
  }

  /// Makes [membershipId] the user's current membership (saved on the profile).
  Future<void> switchMembership(int membershipId) async {
    await _apiClient.post<void>(AppConstants.switchMembershipEndpoint, data: {'membership_id': membershipId});
  }

  Future<void> declineInvite(String code) async {
    await _apiClient.post<void>(AppConstants.declineInviteEndpoint, data: {'invite_code': code});
  }

  Future<void> cancelJoinRequest(int requestId) async {
    await _apiClient.delete<void>('${AppConstants.joinRequestEndpoint}/$requestId');
  }

  Future<void> _memberAction(int membershipId, String action) async {
    await _apiClient.post<void>('${AppConstants.managerMembersEndpoint}/$membershipId/$action');
  }

  MessPersonEntity? _person(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return MessPersonEntity(userId: value['user_id'] as int, name: value['name'] as String? ?? '', email: value['email'] as String? ?? '', phone: value['phone'] as String? ?? '');
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
    seasonStartDate: DateTime.tryParse(json['season_start_date'] as String? ?? ''),
    seasonEndDate: DateTime.tryParse(json['season_end_date'] as String? ?? ''),
    joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '')?.toLocal(),
    isCurrent: json['is_current'] as bool? ?? false,
    canSwitch: json['can_switch'] as bool? ?? false,
  );
}
