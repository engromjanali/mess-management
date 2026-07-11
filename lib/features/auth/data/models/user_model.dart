import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model - Data transfer object with JSON serialization
@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    required String name,
    String? phone,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'current_season') CurrentSeasonModel? currentSeason,
    @Default('member') String role,
  }) = _UserModel;

  /// From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// Convert model to entity
  UserEntity toEntity() {
    return UserEntity(id: id, email: email, name: name, phone: phone, photoUrl: photoUrl, currentSeason: currentSeason?.toEntity(), role: role);
  }

  /// Create model from entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(id: entity.id, email: entity.email, name: entity.name, phone: entity.phone, photoUrl: entity.photoUrl, currentSeason: entity.currentSeason == null ? null : CurrentSeasonModel.fromEntity(entity.currentSeason!), role: entity.role);
  }
}

@freezed
abstract class CurrentSeasonModel with _$CurrentSeasonModel {
  const CurrentSeasonModel._();

  const factory CurrentSeasonModel({
    required int id,
    required String name,
    @JsonKey(name: 'mess_id') required int messId,
    @JsonKey(name: 'mess_name') required String messName,
    required String status,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
  }) = _CurrentSeasonModel;

  factory CurrentSeasonModel.fromJson(Map<String, dynamic> json) => _$CurrentSeasonModelFromJson(json);

  CurrentSeasonEntity toEntity() {
    return CurrentSeasonEntity(id: id, name: name, messId: messId, messName: messName, status: status, startDate: startDate, endDate: endDate);
  }

  factory CurrentSeasonModel.fromEntity(CurrentSeasonEntity entity) {
    return CurrentSeasonModel(id: entity.id, name: entity.name, messId: entity.messId, messName: entity.messName, status: entity.status, startDate: entity.startDate, endDate: entity.endDate);
  }
}
