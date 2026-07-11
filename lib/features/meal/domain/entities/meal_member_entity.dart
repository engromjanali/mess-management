import 'package:equatable/equatable.dart';

/// A single mess member that meals can be recorded against.
class MealMemberEntity extends Equatable {
  final String id;
  final String name;

  const MealMemberEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// One member's meal record for a single day (breakfast / lunch / dinner).
///
/// The admin-facing counterpart to [MealEntity]: it carries the owning
/// [memberId] so a single flat list can hold every member's days.
class MemberMealEntity extends Equatable {
  final String memberId;
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const MemberMealEntity({required this.memberId, required this.date, this.breakfast = 0, this.lunch = 0, this.dinner = 0});

  double get total => breakfast + lunch + dinner;

  /// Whether this record falls on the same calendar day as [other].
  bool sameDay(DateTime other) => date.year == other.year && date.month == other.month && date.day == other.day;

  @override
  List<Object?> get props => [memberId, date, breakfast, lunch, dinner];
}

/// Aggregated data for the admin meal-management view: the roster of members,
/// the shared meal rate and every per-member day record.
class MealAdminEntity extends Equatable {
  final List<MealMemberEntity> members;
  final double mealRate;
  final List<MemberMealEntity> entries;
  final MealMutationEntity? mutation;

  const MealAdminEntity({required this.members, required this.mealRate, required this.entries, this.mutation});

  /// Display name for [memberId], or `Unknown` if it isn't on the roster.
  String memberName(String memberId) => members
      .firstWhere(
        (m) => m.id == memberId,
        orElse: () => const MealMemberEntity(id: '', name: 'Unknown'),
      )
      .name;

  /// Records filtered by an optional [memberId] and/or [date], most recent
  /// first. Passing `null` for either leaves that dimension unfiltered.
  List<MemberMealEntity> filtered({String? memberId, DateTime? date}) {
    final result = entries.where((e) {
      if (memberId != null && e.memberId != memberId) return false;
      if (date != null && !e.sameDay(date)) return false;
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  List<Object?> get props => [members, mealRate, entries, mutation];
}

class MealMutationEntity extends Equatable {
  final String action;
  final int createdCount;
  final int updatedCount;

  const MealMutationEntity({required this.action, required this.createdCount, required this.updatedCount});

  @override
  List<Object?> get props => [action, createdCount, updatedCount];
}
