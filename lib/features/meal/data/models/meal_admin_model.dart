import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';

/// Data-layer DTO for a mess member.
///
/// Plain DTO (no JSON codegen) while served from a local mock source. Add
/// `fromJson`/`toJson` here when a real API is wired up — the domain and
/// presentation layers won't change.
class MealMemberModel {
  final String id;
  final String name;

  const MealMemberModel({required this.id, required this.name});

  MealMemberEntity toEntity() => MealMemberEntity(id: id, name: name);
}

/// Data-layer DTO for one member's single-day meal record.
class MemberMealModel {
  final String memberId;
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const MemberMealModel({
    required this.memberId,
    required this.date,
    this.breakfast = 0,
    this.lunch = 0,
    this.dinner = 0,
  });

  MemberMealEntity toEntity() => MemberMealEntity(
        memberId: memberId,
        date: date,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
      );
}

/// Data-layer DTO for the full admin meal-management payload.
class MealAdminModel {
  final List<MealMemberModel> members;
  final double mealRate;
  final List<MemberMealModel> entries;

  const MealAdminModel({
    required this.members,
    required this.mealRate,
    required this.entries,
  });

  MealAdminEntity toEntity() => MealAdminEntity(
        members: members.map((m) => m.toEntity()).toList(),
        mealRate: mealRate,
        entries: entries.map((e) => e.toEntity()).toList(),
      );
}
