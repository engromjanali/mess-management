import 'package:equatable/equatable.dart';

/// The signed-in user's current mess and its active season
/// (`GET /api/v1/user/mess`).
class MessDetailsEntity extends Equatable {
  final int id;
  final String name;
  final String address;
  final String email;
  final String phone;
  final MessSeasonInfoEntity season;

  /// `manager`, `acting_manager` or `member`.
  final String myRole;
  final DateTime joinedAt;
  final MessPersonEntity? manager;
  final MessPersonEntity? actingManager;

  /// Active members of the season: manager, acting manager, then by name.
  final List<MessMemberEntity> members;
  final MessStatsEntity stats;
  final bool canEdit;
  final bool canTransfer;
  final bool canLeave;

  const MessDetailsEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.phone,
    required this.season,
    required this.myRole,
    required this.joinedAt,
    required this.manager,
    required this.actingManager,
    required this.members,
    required this.stats,
    required this.canEdit,
    required this.canTransfer,
    required this.canLeave,
  });

  @override
  List<Object?> get props => [id, name, address, email, phone, season, myRole, joinedAt, manager, actingManager, members, stats, canEdit, canTransfer, canLeave];
}

class MessSeasonInfoEntity extends Equatable {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;

  const MessSeasonInfoEntity({required this.id, required this.name, required this.startDate, this.endDate});

  /// 1-based day of the season on [now] (day 1 is the start date).
  int dayOn(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays + 1;
  }

  @override
  List<Object?> get props => [id, name, startDate, endDate];
}

/// The manager or acting manager, with contact details.
class MessPersonEntity extends Equatable {
  final int userId;
  final String name;
  final String email;
  final String phone;

  const MessPersonEntity({required this.userId, required this.name, required this.email, required this.phone});

  @override
  List<Object?> get props => [userId, name, email, phone];
}

class MessMemberEntity extends Equatable {
  final int membershipId;
  final int userId;
  final String name;

  /// `manager`, `acting_manager` or `member`.
  final String role;
  final DateTime joinedAt;

  const MessMemberEntity({required this.membershipId, required this.userId, required this.name, required this.role, required this.joinedAt});

  @override
  List<Object?> get props => [membershipId, userId, name, role, joinedAt];
}

/// The active season's numbers (the fund balance spans every season).
class MessStatsEntity extends Equatable {
  final int members;
  final double totalMeals;
  final double mealRate;
  final double totalCost;
  final double totalDeposit;
  final double fundBalance;

  const MessStatsEntity({required this.members, required this.totalMeals, required this.mealRate, required this.totalCost, required this.totalDeposit, required this.fundBalance});

  @override
  List<Object?> get props => [members, totalMeals, mealRate, totalCost, totalDeposit, fundBalance];
}
