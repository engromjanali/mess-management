import 'package:mess_pilot/features/splash/domain/entities/support_channel_entity.dart';

class SupportChannelModel extends SupportChannelEntity {
  const SupportChannelModel({required super.name, required super.kind, required super.destination, required super.url, super.logoUrl});

  factory SupportChannelModel.fromJson(Map<String, dynamic> json) => SupportChannelModel(
    name: json['name'] as String? ?? '',
    kind: json['kind'] as String? ?? 'other',
    destination: json['destination'] as String? ?? '',
    url: json['url'] as String? ?? '',
    logoUrl: json['logo_url'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'name': name, 'kind': kind, 'destination': destination, 'url': url, 'logo_url': logoUrl};
}
