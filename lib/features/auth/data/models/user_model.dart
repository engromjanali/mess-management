import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model - Data transfer object with JSON serialization
@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({required String id, required String email, required String name, @JsonKey(name: 'photo_url') String? photoUrl}) = _UserModel;

  /// From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// Convert model to entity
  UserEntity toEntity() {
    return UserEntity(id: id, email: email, name: name, photoUrl: photoUrl);
  }

  /// Create model from entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(id: entity.id, email: entity.email, name: entity.name, photoUrl: entity.photoUrl);
  }
}
