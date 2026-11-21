import 'package:mess_pilot/features/home/domain/entities/dashboard_entity.dart';

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
  final String managerName;
  final String managerEmail;
  final String managerPhone;
  final String actingManagerName;
  final String actingManagerEmail;
  final String actingManagerPhone;
  final String messAddress;
  final String currentSeasonName;
  final double myTotalMeal;
  final double myDeposit;
  final double myRemaining;
  final List<MemberStatModel> members;
  final NoticeModel? pinnedNotice;
  final bool isManager;
  final bool isMember;
  final String userName;

  const DashboardModel({
    required this.totalBalance,
    required this.mealBalance,
    required this.fundBalance,
    required this.totalDeposit,
    required this.bazerCost,
    required this.totalMeal,
    required this.mealRate,
    required this.managerName,
    required this.managerEmail,
    required this.managerPhone,
    required this.actingManagerName,
    required this.actingManagerEmail,
    required this.actingManagerPhone,
    required this.messAddress,
    required this.currentSeasonName,
    required this.myTotalMeal,
    required this.myDeposit,
    required this.myRemaining,
    required this.members,
    required this.userName,
    this.isManager = false,
    this.isMember = true,
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
    managerName: managerName,
    managerEmail: managerEmail,
    managerPhone: managerPhone,
    actingManagerName: actingManagerName,
    actingManagerEmail: actingManagerEmail,
    actingManagerPhone: actingManagerPhone,
    messAddress: messAddress,
    currentSeasonName: currentSeasonName,
    myTotalMeal: myTotalMeal,
    myDeposit: myDeposit,
    myRemaining: myRemaining,
    members: members.map((m) => m.toEntity()).toList(),
    pinnedNotice: pinnedNotice?.toEntity(),
    isManager: isManager,
    isMember: isMember,
    userName: userName,
  );

  Map<String, dynamic> toJson() => {
    'total_balance': totalBalance,
    'meal_balance': mealBalance,
    'fund_balance': fundBalance,
    'total_deposit': totalDeposit,
    'bazer_cost': bazerCost,
    'total_meal': totalMeal,
    'meal_rate': mealRate,
    'manager_name': managerName,
    'manager_email': managerEmail,
    'manager_phone': managerPhone,
    'acting_manager_name': actingManagerName,
    'acting_manager_email': actingManagerEmail,
    'acting_manager_phone': actingManagerPhone,
    'mess_address': messAddress,
    'current_season_name': currentSeasonName,
    'my_total_meal': myTotalMeal,
    'my_deposit': myDeposit,
    'my_remaining': myRemaining,
    'members': members.map((m) => m.toJson()).toList(),
    'pinned_notice': pinnedNotice?.toJson(),
    'is_manager': isManager,
    'is_member': isMember,
    'user_name': userName,
  };

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
    totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
    mealBalance: (json['meal_balance'] as num?)?.toDouble() ?? 0.0,
    fundBalance: (json['fund_balance'] as num?)?.toDouble() ?? 0.0,
    totalDeposit: (json['total_deposit'] as num?)?.toDouble() ?? 0.0,
    bazerCost: (json['bazer_cost'] as num?)?.toDouble() ?? 0.0,
    totalMeal: (json['total_meal'] as num?)?.toDouble() ?? 0.0,
    mealRate: (json['meal_rate'] as num?)?.toDouble() ?? 0.0,
    managerName: json['manager_name'] as String? ?? '',
    managerEmail: json['manager_email'] as String? ?? '',
    managerPhone: json['manager_phone'] as String? ?? '',
    actingManagerName: json['acting_manager_name'] as String? ?? '',
    actingManagerEmail: json['acting_manager_email'] as String? ?? '',
    actingManagerPhone: json['acting_manager_phone'] as String? ?? '',
    messAddress: json['mess_address'] as String? ?? '',
    currentSeasonName: json['current_season_name'] as String? ?? '',
    myTotalMeal: (json['my_total_meal'] as num?)?.toDouble() ?? 0.0,
    myDeposit: (json['my_deposit'] as num?)?.toDouble() ?? 0.0,
    myRemaining: (json['my_remaining'] as num?)?.toDouble() ?? 0.0,
    members: (json['members'] as List<dynamic>? ?? []).map((m) => MemberStatModel.fromJson(m as Map<String, dynamic>)).toList(),
    pinnedNotice: json['pinned_notice'] != null ? NoticeModel.fromJson(json['pinned_notice'] as Map<String, dynamic>) : null,
    isManager: json['is_manager'] as bool? ?? false,
    isMember: json['is_member'] as bool? ?? true,
    userName: json['user_name'] as String? ?? '',
  );
}

class MemberStatModel {
  final String? photoUrl;
  final String id;
  final String name;
  final double deposit;
  final double meal;

  const MemberStatModel({required this.id, required this.name, required this.deposit, required this.meal, this.photoUrl});

  MemberStatEntity toEntity() => MemberStatEntity(photoUrl: photoUrl, id: id, name: name, deposit: deposit, meal: meal);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deposit': deposit,
    'meal': meal,
    'photo_url': photoUrl,
  };

  factory MemberStatModel.fromJson(Map<String, dynamic> json) => MemberStatModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    deposit: (json['deposit'] as num?)?.toDouble() ?? 0.0,
    meal: (json['meal'] as num?)?.toDouble() ?? 0.0,
    photoUrl: json['photo_url'] as String?,
  );
}

class NoticeModel {
  final String noticeId;
  final String title;
  final String description;
  final DateTime createdAt;

  const NoticeModel({required this.noticeId, required this.title, required this.description, required this.createdAt});

  NoticeEntity toEntity() => NoticeEntity(noticeId: noticeId, title: title, description: description, createdAt: createdAt);

  Map<String, dynamic> toJson() => {
    'notice_id': noticeId,
    'title': title,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };

  factory NoticeModel.fromJson(Map<String, dynamic> json) => NoticeModel(
    noticeId: json['notice_id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
