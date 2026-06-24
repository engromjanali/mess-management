import 'package:equatable/equatable.dart';

/// A mess notice / announcement.
class NoticeEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  const NoticeEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, description, createdAt];
}
