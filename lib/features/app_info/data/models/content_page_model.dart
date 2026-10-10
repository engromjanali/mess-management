import 'package:clean_boilerplate/features/app_info/domain/entities/content_page_entity.dart';

/// Data-layer DTO for `/api/v1/app/pages/<kind>`.
class ContentPageModel {
  const ContentPageModel({required this.title, required this.body, required this.updatedAt});

  factory ContentPageModel.fromJson(Map<String, dynamic> json) => ContentPageModel(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
  );

  final String title;
  final String body;
  final DateTime updatedAt;

  ContentPageEntity toEntity() => ContentPageEntity(title: title, body: body, updatedAt: updatedAt);
}
