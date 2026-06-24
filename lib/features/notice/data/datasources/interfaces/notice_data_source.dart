import '../../models/notice_model.dart';

/// Contract for any source that can provide & mutate notices.
abstract class NoticeDataSource {
  Future<List<NoticeModel>> getNotices();

  Future<NoticeModel> addNotice({
    required String title,
    required String description,
  });

  Future<NoticeModel> updateNotice({
    required String id,
    required String title,
    required String description,
  });

  /// Pins or unpins a notice. Pinning one unpins any other.
  Future<void> setPinned({required String id, required bool pinned});

  Future<void> deleteNotice(String id);
}
