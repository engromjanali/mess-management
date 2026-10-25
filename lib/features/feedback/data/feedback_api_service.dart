import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/feedback/domain/entities/feedback_entity.dart';

typedef FeedbackPage = ({int? nextPage, List<FeedbackEntity> feedbacks});
typedef FeedbackCommentsPage = ({int? nextPage, List<FeedbackCommentEntity> comments});
typedef FeedbackImageUpload = ({String name, Uint8List bytes});

class FeedbackApiService {
  const FeedbackApiService(this._apiClient);

  final ApiClient _apiClient;
  static final _privateOptions = Options(extra: {'sensitive': true});

  Future<FeedbackPage> getFeedbacks({int page = 1, CancelToken? cancelToken}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      AppConstants.feedbacksEndpoint,
      queryParameters: {'page': page},
      options: _privateOptions,
      cancelToken: cancelToken,
    );
    final json = response.data!;
    return (
      nextPage: (json['next_page'] as num?)?.toInt(),
      feedbacks: (json['data'] as List<dynamic>).map((item) => _feedback(item as Map<String, dynamic>)).toList(),
    );
  }

  Future<FeedbackEntity> submitFeedback({
    required String description,
    List<FeedbackImageUpload> images = const [],
  }) async {
    final files = <MapEntry<String, MultipartFile>>[];
    for (final img in images) {
      files.add(MapEntry(
        'images',
        MultipartFile.fromBytes(img.bytes, filename: img.name.isNotEmpty ? img.name : 'image.jpg'),
      ));
    }
    final response = await _apiClient.postMultipart<Map<String, dynamic>>(
      AppConstants.feedbacksEndpoint,
      data: {'description': description},
      files: files.isNotEmpty ? files : null,
      options: _privateOptions,
    );
    return _feedback(response.data!);
  }

  Future<FeedbackCommentEntity> addComment({
    required String feedbackId,
    required String comment,
    FeedbackImageUpload? image,
  }) async {
    final files = <MapEntry<String, MultipartFile>>[];
    if (image != null) {
      files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(image.bytes, filename: image.name.isNotEmpty ? image.name : 'comment_image.jpg'),
      ));
    }
    final response = await _apiClient.postMultipart<Map<String, dynamic>>(
      '${AppConstants.feedbacksEndpoint}/$feedbackId/comments',
      data: {'comment': comment},
      files: files.isNotEmpty ? files : null,
      options: _privateOptions,
    );
    return _comment(response.data!);
  }

  Future<FeedbackCommentsPage> getComments(String feedbackId, {int page = 1}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.feedbacksEndpoint}/$feedbackId/comments',
      queryParameters: {'page': page},
      options: _privateOptions,
    );
    final json = response.data!;
    return (
      nextPage: (json['next_page'] as num?)?.toInt(),
      comments: (json['data'] as List<dynamic>).map((item) => _comment(item as Map<String, dynamic>)).toList(),
    );
  }

  FeedbackEntity _feedback(Map<String, dynamic> json) => FeedbackEntity(
    id: '${json['id']}',
    description: json['description'] as String,
    images: (json['images'] as List<dynamic>?)?.whereType<String>().toList() ?? [],
    authorName: json['author_name'] as String? ?? '',
    authorPhotoUrl: json['author_photo_url'] as String?,
    isAuthor: json['is_author'] as bool? ?? false,
    isPublic: json['is_public'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    comments: (json['comments'] as List<dynamic>?)
            ?.map((item) => _comment(item as Map<String, dynamic>))
            .toList() ??
        [],
  );

  FeedbackCommentEntity _comment(Map<String, dynamic> json) => FeedbackCommentEntity(
    id: '${json['id']}',
    comment: json['comment'] as String? ?? '',
    imageUrl: json['image_url'] as String?,
    authorName: json['author_name'] as String? ?? '',
    authorPhotoUrl: json['author_photo_url'] as String?,
    isAuthor: json['is_author'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );
}
