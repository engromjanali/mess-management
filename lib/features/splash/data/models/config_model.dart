import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'config_model.freezed.dart';
part 'config_model.g.dart';

ConfigModel configModelFromJson(String str) => ConfigModel.fromJson(json.decode(str));

String configModelToJson(ConfigModel data) => json.encode(data.toJson());

@freezed
abstract class ConfigModel with _$ConfigModel {
  const ConfigModel._();

  const factory ConfigModel({
    @JsonKey(name: 'latest_version') @Default('1.0.0') String latestVersion,
    @JsonKey(name: 'minimum_version') @Default('1.0.0') String minimumVersion,
    @JsonKey(name: 'update_message') @Default('') String updateMessage,
    @JsonKey(name: 'android_store_url') @Default('') String androidStoreUrl,
    @JsonKey(name: 'ios_store_url') @Default('') String iosStoreUrl,
    @Default(MaintenanceModel()) MaintenanceModel maintenance,
    @JsonKey(name: 'support_email') @Default('') String supportEmail,
  }) = _ConfigModel;

  factory ConfigModel.fromJson(Map<String, dynamic> json) => _$ConfigModelFromJson(json);

  ConfigEntity toEntity() {
    return ConfigEntity(
      latestVersion: latestVersion,
      minimumVersion: minimumVersion,
      updateMessage: updateMessage,
      androidStoreUrl: androidStoreUrl,
      iosStoreUrl: iosStoreUrl,
      maintenanceMode: maintenance.enabled,
      maintenanceMessage: maintenance.message,
      maintenanceUntil: maintenance.until?.toLocal(),
      supportEmail: supportEmail,
    );
  }
}

@freezed
abstract class MaintenanceModel with _$MaintenanceModel {
  const factory MaintenanceModel({@Default(false) bool enabled, @Default('') String message, DateTime? until}) = _MaintenanceModel;

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) => _$MaintenanceModelFromJson(json);
}
