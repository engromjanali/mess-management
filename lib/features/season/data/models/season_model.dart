import 'package:clean_boilerplate/features/season/domain/entities/auto_create_season_entity.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_overview_entity.dart';

/// Data-layer DTO for a season (`/api/v1/admin/seasons` item).
class SeasonModel {
  const SeasonModel({required this.id, required this.name, required this.startDate, this.endDate, this.disabled = false, this.memberCount = 0});

  /// Dates come as `yyyy-MM-dd`.
  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    final endDate = json['end_date'] as String?;
    return SeasonModel(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: endDate == null ? null : DateTime.parse(endDate),
      disabled: json['is_disabled'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final bool disabled;
  final int memberCount;

  SeasonModel copyWith({String? name, DateTime? startDate, DateTime? endDate, bool clearEndDate = false, bool? disabled}) => SeasonModel(
    id: id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    disabled: disabled ?? this.disabled,
    memberCount: memberCount,
  );

  SeasonEntity toEntity() => SeasonEntity(id: id, name: name, startDate: startDate, endDate: endDate, disabled: disabled, memberCount: memberCount);
}

/// Data-layer DTO for `GET /api/v1/admin/seasons`.
class SeasonOverviewModel {
  const SeasonOverviewModel({required this.seasons, required this.currentSeasonId, required this.autoCreate});

  factory SeasonOverviewModel.fromJson(Map<String, dynamic> json) {
    final currentId = json['current_season_id'];
    return SeasonOverviewModel(
      seasons: (json['seasons'] as List<dynamic>? ?? []).map((item) => SeasonModel.fromJson(item as Map<String, dynamic>)).toList(),
      currentSeasonId: currentId == null ? null : '$currentId',
      autoCreate: autoCreateFromJson(json['auto_create'] as Map<String, dynamic>? ?? const {}),
    );
  }

  /// `{enabled, day}`; day 0 = the month's last day.
  static AutoCreateSeasonEntity autoCreateFromJson(Map<String, dynamic> json) =>
      AutoCreateSeasonEntity(enabled: json['enabled'] as bool? ?? false, day: json['day'] as int? ?? AutoCreateSeasonEntity.monthEnd);

  final List<SeasonModel> seasons;
  final String? currentSeasonId;
  final AutoCreateSeasonEntity autoCreate;

  SeasonOverviewEntity toEntity() => SeasonOverviewEntity(seasons: seasons.map((s) => s.toEntity()).toList(), currentSeasonId: currentSeasonId, autoCreate: autoCreate);
}
