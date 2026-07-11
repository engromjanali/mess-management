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

  factory MealMemberModel.fromJson(Map<String, dynamic> json) {
    return MealMemberModel(id: '${json['id']}', name: json['name'] as String? ?? '');
  }

  MealMemberEntity toEntity() => MealMemberEntity(id: id, name: name);
}

/// Data-layer DTO for one member's single-day meal record.
class MemberMealModel {
  final String memberId;
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;

  const MemberMealModel({required this.memberId, required this.date, this.breakfast = 0, this.lunch = 0, this.dinner = 0});

  factory MemberMealModel.fromJson(Map<String, dynamic> json) {
    return MemberMealModel(
      memberId: '${json['member_id']}',
      date: DateTime.parse(json['date'] as String),
      breakfast: (json['breakfast'] as num?)?.toDouble() ?? 0,
      lunch: (json['lunch'] as num?)?.toDouble() ?? 0,
      dinner: (json['dinner'] as num?)?.toDouble() ?? 0,
    );
  }

  MemberMealEntity toEntity() => MemberMealEntity(memberId: memberId, date: date, breakfast: breakfast, lunch: lunch, dinner: dinner);
}

/// Data-layer DTO for the full admin meal-management payload.
class MealAdminModel {
  final List<MealMemberModel> members;
  final double mealRate;
  final List<MemberMealModel> entries;
  final MealMutationModel? mutation;

  const MealAdminModel({required this.members, required this.mealRate, required this.entries, this.mutation});

  factory MealAdminModel.fromJson(Map<String, dynamic> json) {
    return MealAdminModel(
      members: (json['members'] as List<dynamic>? ?? []).map((item) => MealMemberModel.fromJson(item as Map<String, dynamic>)).toList(),
      mealRate: (json['meal_rate'] as num?)?.toDouble() ?? 0,
      entries: (json['entries'] as List<dynamic>? ?? []).map((item) => MemberMealModel.fromJson(item as Map<String, dynamic>)).toList(),
      mutation: json['mutation'] is Map<String, dynamic> ? MealMutationModel.fromJson(json['mutation'] as Map<String, dynamic>) : null,
    );
  }

  MealAdminEntity toEntity() => MealAdminEntity(members: members.map((m) => m.toEntity()).toList(), mealRate: mealRate, entries: entries.map((e) => e.toEntity()).toList(), mutation: mutation?.toEntity());
}

class MealMutationModel {
  final String action;
  final int createdCount;
  final int updatedCount;

  const MealMutationModel({required this.action, required this.createdCount, required this.updatedCount});

  factory MealMutationModel.fromJson(Map<String, dynamic> json) {
    return MealMutationModel(action: json['action'] as String? ?? '', createdCount: json['created_count'] as int? ?? 0, updatedCount: json['updated_count'] as int? ?? 0);
  }

  MealMutationEntity toEntity() => MealMutationEntity(action: action, createdCount: createdCount, updatedCount: updatedCount);
}
