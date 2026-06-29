import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/features/home/data/models/dashboard_model.dart';
import 'package:clean_boilerplate/features/home/data/datasources/interfaces/home_data_source.dart';

/// Local mock data source.
///
/// Returns representative sample data so the redesigned home screen is fully
/// previewable without a backend. Swap this binding for a remote
/// implementation later — the repository and presentation layers won't change.
@LazySingleton(as: HomeDataSource)
class HomeLocalDataSourceImpl implements HomeDataSource {
  @override
  Future<DashboardModel> getDashboard() async {
    // Simulate network/IO latency so loading + refresh states are visible.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    const mealRate = 62.5;
    final members = <MemberStatModel>[
      const MemberStatModel(id: '1', name: 'Romjan Ali', deposit: 3000, meal: 41),
      const MemberStatModel(id: '2', name: 'Mehedi Hasan', deposit: 2500, meal: 38),
      const MemberStatModel(id: '3', name: 'Sakib Khan', deposit: 2800, meal: 45),
      const MemberStatModel(id: '4', name: 'Tanvir Ahmed', deposit: 2200, meal: 30),
      const MemberStatModel(id: '5', name: 'Rakib Hossain', deposit: 3200, meal: 52),
      const MemberStatModel(id: '6', name: 'Jisan Mahmud', deposit: 2000, meal: 27),
      const MemberStatModel(id: '7', name: 'Nayeem Islam', deposit: 2600, meal: 36),
    ];

    final totalDeposit = members.fold<double>(0, (sum, m) => sum + m.deposit);
    final totalMeal = members.fold<double>(0, (sum, m) => sum + m.meal);
    const bazerCost = 12450.0;
    const fundBalance = 4500.0;
    final mealBalance = totalDeposit - bazerCost;
    final totalBalance = mealBalance + fundBalance;

    return DashboardModel(
      userName: 'Romjan',
      isManager: true,
      totalBalance: totalBalance,
      mealBalance: mealBalance,
      fundBalance: fundBalance,
      totalDeposit: totalDeposit,
      bazerCost: bazerCost,
      totalMeal: totalMeal,
      mealRate: mealRate,
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
