import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/home/data/models/dashboard_model.dart';
import 'package:clean_boilerplate/features/home/data/datasources/interfaces/home_data_source.dart';

/// Live mess/member totals with the remaining dashboard placeholders.
@LazySingleton(as: HomeDataSource)
class HomeLocalDataSourceImpl implements HomeDataSource {
  HomeLocalDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DashboardModel> getDashboard() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.messDetailsEndpoint, options: Options(extra: {'sensitive': true}));
    final json = response.data!;
    final stats = json['stats'] as Map<String, dynamic>;
    final mealRate = (stats['meal_rate'] as num).toDouble();
    final members = (json['member_stats'] as List<dynamic>? ?? const []).map((item) {
      final member = item as Map<String, dynamic>;
      return MemberStatModel(id: '${member['id']}', name: member['name'] as String, deposit: (member['deposit'] as num).toDouble(), meal: (member['meal'] as num).toDouble());
    }).toList();

    final totalDeposit = (stats['total_deposit'] as num).toDouble();
    final totalMeal = (stats['total_meals'] as num).toDouble();
    final bazerCost = (stats['total_cost'] as num).toDouble();
    final fundBalance = (stats['fund_balance'] as num).toDouble();
    final mealBalance = totalDeposit - bazerCost;
    final totalBalance = mealBalance + fundBalance;

    return DashboardModel(
      userName: 'Romjan',
      isManager: const ['manager', 'acting_manager'].contains(json['my_role']),
      totalBalance: totalBalance,
      mealBalance: mealBalance,
      fundBalance: fundBalance,
      totalDeposit: totalDeposit,
      bazerCost: bazerCost,
      totalMeal: totalMeal,
      mealRate: mealRate,
      managerEmail: 'manager@messmanager.com',
      managerPhone: '+880 1712-345678',
      actingManagerEmail: 'acting.manager@messmanager.com',
      actingManagerPhone: '+880 1812-345678',
      messAddress: 'Mirpur-10, Dhaka, Bangladesh',
      myTotalMeal: 41,
      myDeposit: 3000,
      myRemaining: 3000 - (41 * mealRate),
      members: members,
      pinnedNotice: NoticeModel(
        noticeId: '#1042',
        title: 'Monthly meal rate updated',
        description:
            'The meal rate for this session has been recalculated to ৳62.5. '
            'Please clear any pending deposits before the 10th.',
        createdAt: DateTime(2026, 6, 1, 9, 30),
      ),
    );
  }
}
