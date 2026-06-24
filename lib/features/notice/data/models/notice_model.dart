import '../../domain/entities/notice_entity.dart';

/// Data-layer DTO for a notice.
class NoticeModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  NoticeModel copyWith({String? title, String? description}) {
    return NoticeModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  NoticeEntity toEntity() => NoticeEntity(
        id: id,
        title: title,
        description: description,
        createdAt: createdAt,
      );
}
