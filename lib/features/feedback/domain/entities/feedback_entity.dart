class FeedbackCommentEntity {
  const FeedbackCommentEntity({
    required this.id,
    required this.comment,
    required this.authorName,
    required this.isAuthor,
    required this.createdAt,
    this.imageUrl,
    this.authorPhotoUrl,
  });

  final String id;
  final String comment;
  final String? imageUrl;
  final String authorName;
  final String? authorPhotoUrl;
  final bool isAuthor;
  final DateTime createdAt;
}

class FeedbackEntity {
  const FeedbackEntity({
    required this.id,
    required this.description,
    required this.images,
    required this.authorName,
    required this.isAuthor,
    required this.isPublic,
    required this.createdAt,
    required this.commentsCount,
    this.authorPhotoUrl,
    this.comments = const [],
  });

  final String id;
  final String description;
  final List<String> images;
  final String authorName;
  final String? authorPhotoUrl;
  final bool isAuthor;
  final bool isPublic;
  final DateTime createdAt;
  final int commentsCount;
  final List<FeedbackCommentEntity> comments;

  FeedbackEntity copyWith({
    String? id,
    String? description,
    List<String>? images,
    String? authorName,
    String? authorPhotoUrl,
    bool? isAuthor,
    bool? isPublic,
    DateTime? createdAt,
    int? commentsCount,
    List<FeedbackCommentEntity>? comments,
  }) {
    return FeedbackEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      images: images ?? this.images,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      isAuthor: isAuthor ?? this.isAuthor,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
    );
  }
}
