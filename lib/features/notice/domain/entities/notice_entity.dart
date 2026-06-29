import 'package:equatable/equatable.dart';

/// A mess notice / announcement.
class NoticeEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  /// Whether this notice is the one pinned to the top / dashboard. At most one
  /// notice is pinned at a time.
  final bool pinned;

  const NoticeEntity({required this.id, required this.title, required this.description, required this.createdAt, this.pinned = false});

  @override
  List<Object?> get props => [id, title, description, createdAt, pinned];
}
