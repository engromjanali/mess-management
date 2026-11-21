import 'dart:convert';

import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/errors/exceptions.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/home/data/models/dashboard_model.dart';
import 'package:mess_pilot/features/home/data/datasources/interfaces/home_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live mess, personal and member totals for the selected season.
@LazySingleton(as: HomeDataSource)
class HomeLocalDataSourceImpl implements HomeDataSource {
  HomeLocalDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;
  static const String _cacheKey = 'cached_home_dashboard';

  @override
  DashboardModel? getCachedDashboard() {
    try {
      final jsonStr = getIt<SharedPreferences>().getString(_cacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return DashboardModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCachedDashboard() async {
    try {
      await getIt<SharedPreferences>().remove(_cacheKey);
    } catch (_) {}
  }

  @override
  Future<DashboardModel> getDashboard() async {
    final responses = await Future.wait([
      _apiClient.get<Map<String, dynamic>>(AppConstants.messDetailsEndpoint, options: Options(extra: {'sensitive': true})),
      _apiClient.get<Map<String, dynamic>>(AppConstants.noticesEndpoint).then<Map<String, dynamic>?>((response) => response.data, onError: (Object error) {
        if (error is UnauthorizedException) throw error;
        return null;
      }),
    ]);
    final response = responses[0] as Response<Map<String, dynamic>>;
    final noticesResponse = responses[1] as Map<String, dynamic>?;
    final json = response.data!;
    final myStats = json['my_stats'] as Map<String, dynamic>? ?? const {};
    final manager = json['manager'] as Map<String, dynamic>?;
    final actingManager = json['acting_manager'] as Map<String, dynamic>?;
    final season = json['season'] as Map<String, dynamic>;
    final notices = noticesResponse?['data'] as List<dynamic>? ?? [];
    final pinnedNoticeJson = notices.cast<Map<String, dynamic>>().where((notice) => notice['pinned'] == true).firstOrNull;
    final stats = json['stats'] as Map<String, dynamic>;
    final mealRate = (stats['meal_rate'] as num).toDouble();
    final members = (json['member_stats'] as List<dynamic>? ?? const []).map((item) {
      final member = item as Map<String, dynamic>;
      return MemberStatModel(photoUrl: member['photo'] as String?, id: '${member['id']}', name: member['name'] as String, deposit: (member['deposit'] as num).toDouble(), meal: (member['meal'] as num).toDouble());
    }).toList();

    final totalDeposit = (stats['total_deposit'] as num).toDouble();
    final totalMeal = (stats['total_meals'] as num).toDouble();
    final bazerCost = (stats['total_cost'] as num).toDouble();
    final fundBalance = (stats['fund_balance'] as num).toDouble();
    final mealBalance = totalDeposit - bazerCost;
    final totalBalance = mealBalance + fundBalance;

    final model = DashboardModel(
      userName: '',
      isManager: const ['manager', 'acting_manager'].contains(json['my_role']),
      isMember: json['is_member'] as bool? ?? true,
      totalBalance: totalBalance,
      mealBalance: mealBalance,
      fundBalance: fundBalance,
      totalDeposit: totalDeposit,
      bazerCost: bazerCost,
      totalMeal: totalMeal,
      mealRate: mealRate,
      managerName: manager?['name'] as String? ?? '',
      managerEmail: manager?['email'] as String? ?? '',
      managerPhone: manager?['phone'] as String? ?? '',
      actingManagerName: actingManager?['name'] as String? ?? '',
      actingManagerEmail: actingManager?['email'] as String? ?? '',
      actingManagerPhone: actingManager?['phone'] as String? ?? '',
      messAddress: json['address'] as String? ?? '',
      currentSeasonName: season['name'] as String? ?? '',
      myTotalMeal: (myStats['meal'] as num?)?.toDouble() ?? 0,
      myDeposit: (myStats['deposit'] as num?)?.toDouble() ?? 0,
      myRemaining: (myStats['remaining'] as num?)?.toDouble() ?? 0,
      members: members,
      pinnedNotice: pinnedNoticeJson == null ? null : NoticeModel(noticeId: '${pinnedNoticeJson['id']}', title: pinnedNoticeJson['title'] as String, description: pinnedNoticeJson['description'] as String, createdAt: DateTime.parse(pinnedNoticeJson['created_at'] as String).toLocal()),
    );

    try {
      await getIt<SharedPreferences>().setString(_cacheKey, jsonEncode(model.toJson()));
    } catch (_) {}

    return model;
  }
}
