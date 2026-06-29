import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';

/// Notice repository contract (abstraction in the domain layer).
abstract class NoticeRepository {
  /// Every notice (newest first).
  ResultFuture<List<NoticeEntity>> getNotices();

  /// Publishes a new notice.
  ResultFuture<NoticeEntity> addNotice({required String title, required String description});

  /// Edits an existing notice.
  ResultFuture<NoticeEntity> updateNotice({required String id, required String title, required String description});

  /// Pins or unpins a notice. Pinning one unpins any other.
  ResultVoid setPinned({required String id, required bool pinned});

  /// Removes a notice.
  ResultVoid deleteNotice(String id);
}
