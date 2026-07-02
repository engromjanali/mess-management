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
    required String version,
  }) = _ConfigModel;

  factory ConfigModel.fromJson(Map<String, dynamic> json) => _$ConfigModelFromJson(json);

  ConfigEntity toEntity() {
    return ConfigEntity(
      version: version ,
    );
  }
}
