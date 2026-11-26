import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';

class MealSelectionModel {
  const MealSelectionModel({required this.breakfast, required this.lunch, required this.dinner});

  final double breakfast;
  final double lunch;
  final double dinner;

  factory MealSelectionModel.fromJson(Map<String, dynamic> json) => MealSelectionModel(
        breakfast: (json['breakfast'] as num?)?.toDouble() ?? 0,
        lunch: (json['lunch'] as num?)?.toDouble() ?? 0,
        dinner: (json['dinner'] as num?)?.toDouble() ?? 0,
      );

  MealSelectionEntity toEntity() => MealSelectionEntity(breakfast: breakfast, lunch: lunch, dinner: dinner);
}

class MealRequestModel {
  const MealRequestModel({
    required this.id,
    required this.date,
    required this.description,
    required this.endAt,
    required this.isOpen,
    required this.canRespond,
    required this.canManage,
    required this.responseCount,
    required this.eligibleMemberCount,
    required this.breakfastTotal,
    required this.lunchTotal,
    required this.dinnerTotal,
    this.closedAt,
    this.mySelection,
    this.selections = const [],
  });

  final String id;
  final DateTime date;
  final String description;
  final DateTime endAt;
  final DateTime? closedAt;
  final bool isOpen;
  final bool canRespond;
  final bool canManage;
  final int responseCount;
  final int eligibleMemberCount;
  final double breakfastTotal;
  final double lunchTotal;
  final double dinnerTotal;
  final MealSelectionModel? mySelection;
  final List<MealRequestSelectionItem> selections;

  factory MealRequestModel.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    final selection = json['my_selection'];
    final closedAt = json['closed_at'] as String?;
    return MealRequestModel(
      id: '${json['id']}',
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String? ?? '',
      endAt: DateTime.parse(json['end_at'] as String).toLocal(),
      closedAt: closedAt != null ? DateTime.parse(closedAt).toLocal() : null,
      isOpen: json['is_open'] as bool? ?? false,
      canRespond: json['can_respond'] as bool? ?? false,
      canManage: json['can_manage'] as bool? ?? false,
      responseCount: (json['response_count'] as num?)?.toInt() ?? 0,
      eligibleMemberCount: (json['eligible_member_count'] as num?)?.toInt() ?? 0,
      breakfastTotal: (totals['breakfast'] as num?)?.toDouble() ?? 0,
      lunchTotal: (totals['lunch'] as num?)?.toDouble() ?? 0,
      dinnerTotal: (totals['dinner'] as num?)?.toDouble() ?? 0,
      mySelection: selection is Map<String, dynamic> ? MealSelectionModel.fromJson(selection) : null,
      selections: [
        for (final item in json['selections'] as List<dynamic>? ?? const [])
          if (item is Map<String, dynamic>)
            MealRequestSelectionItem(
              memberId: '${item['member_id']}',
              memberName: item['member_name'] as String? ?? '',
              memberPhoto: item['member_photo'] as String?,
              breakfast: (item['breakfast'] as num?)?.toDouble() ?? 0,
              lunch: (item['lunch'] as num?)?.toDouble() ?? 0,
              dinner: (item['dinner'] as num?)?.toDouble() ?? 0,
            ),
      ],
    );
  }

  MealRequestEntity toEntity() => MealRequestEntity(
        id: id,
        date: date,
        description: description,
        endAt: endAt,
        closedAt: closedAt,
        isOpen: isOpen,
        canRespond: canRespond,
        canManage: canManage,
        responseCount: responseCount,
        eligibleMemberCount: eligibleMemberCount,
        breakfastTotal: breakfastTotal,
        lunchTotal: lunchTotal,
        dinnerTotal: dinnerTotal,
        mySelection: mySelection?.toEntity(),
        selections: selections,
      );
}

class MealRequestOverviewModel {
  const MealRequestOverviewModel({required this.requests, required this.canManage});

  final List<MealRequestModel> requests;
  final bool canManage;

  factory MealRequestOverviewModel.fromJson(Map<String, dynamic> json) => MealRequestOverviewModel(
        requests: (json['data'] as List<dynamic>? ?? const []).map((item) => MealRequestModel.fromJson(item as Map<String, dynamic>)).toList(),
        canManage: json['can_manage'] as bool? ?? false,
      );

  MealRequestOverviewEntity toEntity() => MealRequestOverviewEntity(
        requests: requests.map((item) => item.toEntity()).toList(),
        canManage: canManage,
      );
}
