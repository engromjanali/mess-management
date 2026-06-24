import '../../../../config/util/result.dart';
import '../entities/notice_entity.dart';

/// Notice repository contract (abstraction in the domain layer).
abstract class NoticeRepository {
  /// Every notice (newest first).
  ResultFuture<List<NoticeEntity>> getNotices();

  /// Publishes a new notice.
  ResultFuture<NoticeEntity> addNotice({
    required String title,
    required String description,
  });

  /// Edits an existing notice.
  ResultFuture<NoticeEntity> updateNotice({
    required String id,
    required String title,
    required String description,
  });

  /// Removes a notice.
  ResultVoid deleteNotice(String id);
}
