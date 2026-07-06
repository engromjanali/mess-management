import 'package:equatable/equatable.dart';

/// Aggregated dashboard data for the home screen.
///
/// Pure business object — mirrors every value the legacy `FirstScreen`
/// surfaced (mess summary, personal summary, member breakdown and the
/// pinned notice) but with no framework dependencies.
class DashboardEntity extends Equatable {
  // Mess section
  final double totalBalance;
  final double mealBalance;
  final double fundBalance;
  final double totalDeposit;
  final double bazerCost;
  final double totalMeal;
  final double mealRate;

  // My section
  final double myTotalMeal;
  final double myDeposit;
  final double myRemaining;

  // Member breakdown + pinned notice
  final List<MemberStatEntity> members;
  final NoticeEntity? pinnedNotice;

  /// Whether the current user is a manager/admin (controls member table).
  final bool isManager;

  /// Friendly name shown in the welcome header.
  final String userName;

  const DashboardEntity({
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

  DashboardEntity copyWith({bool? isManager, String? userName}) => DashboardEntity(
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
    members: members,
    userName: userName ?? this.userName,
    isManager: isManager ?? this.isManager,
    pinnedNotice: pinnedNotice,
  );

  @override
  List<Object?> get props => [totalBalance, mealBalance, fundBalance, totalDeposit, bazerCost, totalMeal, mealRate, myTotalMeal, myDeposit, myRemaining, members, pinnedNotice, isManager, userName];
}

/// Per-member statistics rendered in the manager member table.
class MemberStatEntity extends Equatable {
  final String id;
  final String name;
  final double deposit;
  final double meal;

  const MemberStatEntity({required this.id, required this.name, required this.deposit, required this.meal});

  /// Remaining balance for a member given the current meal rate.
  double remaining(double mealRate) => deposit - (meal * mealRate);

  @override
  List<Object?> get props => [id, name, deposit, meal];
}

/// A pinned notice shown on the home screen.
class NoticeEntity extends Equatable {
  final String noticeId;
  final String title;
  final String description;
  final DateTime createdAt;

  const NoticeEntity({required this.noticeId, required this.title, required this.description, required this.createdAt});

  @override
  List<Object?> get props => [noticeId, title, description, createdAt];
}
