import '../../domain/entities/notice_entity.dart';

/// Data-layer DTO for a notice.
class NoticeModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool pinned;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.pinned = false,
  });

  NoticeModel copyWith({
    String? title,
    String? description,
    bool? pinned,
  }) {
    return NoticeModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      pinned: pinned ?? this.pinned,
    );
  }

  NoticeEntity toEntity() => NoticeEntity(
        id: id,
        title: title,
        description: description,
        createdAt: createdAt,
        pinned: pinned,
      );
}
