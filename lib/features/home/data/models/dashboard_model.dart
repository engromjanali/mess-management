import 'package:clean_boilerplate/features/home/domain/entities/dashboard_entity.dart';

/// Data-layer representation of the dashboard.
///
/// Kept as a plain DTO (no JSON codegen) because the boilerplate currently
/// serves this from a local mock data source. When a real API is wired up,
/// add `fromJson`/`toJson` here without touching the domain or presentation.
class DashboardModel {
  final double totalBalance;
  final double mealBalance;
  final double fundBalance;
  final double totalDeposit;
  final double bazerCost;
  final double totalMeal;
  final double mealRate;
  final double myTotalMeal;
  final double myDeposit;
  final double myRemaining;
  final List<MemberStatModel> members;
  final NoticeModel? pinnedNotice;
  final bool isManager;
  final String userName;

  const DashboardModel({
    required this.totalBalance,
    required this.mealBalance,
    required this.fundBalance,
    required this.totalDeposit,
    required this.bazerCost,
    required this.totalMeal,
    required this.mealRate,
    required this.myTotalMeal,
    required this.myDeposit,
    required this.myRemaining,
    required this.members,
    required this.userName,
    this.isManager = false,
    this.pinnedNotice,
  });

  DashboardEntity toEntity() => DashboardEntity(
        totalBalance: totalBalance,
        mealBalance: mealBalance,
        fundBalance: fundBalance,
        totalDeposit: totalDeposit,
        bazerCost: bazerCost,
        totalMeal: totalMeal,
        mealRate: mealRate,
        myTotalMeal: myTotalMeal,
        myDeposit: myDeposit,
        myRemaining: myRemaining,
        members: members.map((m) => m.toEntity()).toList(),
        pinnedNotice: pinnedNotice?.toEntity(),
        isManager: isManager,
        userName: userName,
      );
}

class MemberStatModel {
  final String id;
  final String name;
  final double deposit;
  final double meal;

  const MemberStatModel({
    required this.id,
    required this.name,
    required this.deposit,
    required this.meal,
  });

  MemberStatEntity toEntity() => MemberStatEntity(
        id: id,
        name: name,
        deposit: deposit,
        meal: meal,
      );
}

class NoticeModel {
  final String noticeId;
  final String title;
  final String description;
  final DateTime createdAt;

  const NoticeModel({
    required this.noticeId,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  NoticeEntity toEntity() => NoticeEntity(
        noticeId: noticeId,
        title: title,
        description: description,
        createdAt: createdAt,
      );
}
