import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';

/// Data-layer DTO for a notice.
class NoticeModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool pinned;

  const NoticeModel({required this.id, required this.title, required this.description, required this.createdAt, this.pinned = false});

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: '${json['id']}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      // Sent in UTC; shown in the device's time zone.
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      pinned: json['pinned'] as bool? ?? false,
    );
  }

  NoticeModel copyWith({String? title, String? description, bool? pinned}) {
    return NoticeModel(id: id, title: title ?? this.title, description: description ?? this.description, createdAt: createdAt, pinned: pinned ?? this.pinned);
  }

  NoticeEntity toEntity() => NoticeEntity(id: id, title: title, description: description, createdAt: createdAt, pinned: pinned);
}
