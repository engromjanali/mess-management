import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/features/notice/data/models/notice_model.dart';
import 'package:clean_boilerplate/features/notice/data/datasources/interfaces/notice_data_source.dart';

/// In-memory mock for the notice feature.
///
/// Holds a flat list of notices, newest first. Swap this binding for a remote
/// implementation later — the repository and presentation layers won't change.
@LazySingleton(as: NoticeDataSource)
class NoticeLocalDataSourceImpl implements NoticeDataSource {
  /// Session-mutable store of notices, seeded with a few records.
  final List<NoticeModel> _notices = [
    NoticeModel(
      id: 'n1',
      title: 'Meal rate updated',
      description:
          'This month\'s meal rate has been revised to ৳62.5 per meal. '
          'Please review your deposits accordingly.',
      createdAt: DateTime(2026, 6, 22, 9, 30),
      pinned: true,
    ),
    NoticeModel(
      id: 'n2',
      title: 'Bazar duty roster',
      description:
          'The new bazar duty roster is posted on the board. Check your '
          'assigned days and swap early if needed.',
      createdAt: DateTime(2026, 6, 18, 20, 15),
    ),
    NoticeModel(
      id: 'n3',
      title: 'Guest meal policy',
      description:
          'Guest meals must be informed before 10:00 AM. Late entries will '
          'not be counted for the day.',
      createdAt: DateTime(2026, 6, 12, 11),
    ),
  ];

  /// Monotonic counter for generating new ids within the session.
  int _seq = 100;

  String _nextId() => 'n${_seq++}';

  List<NoticeModel> _sorted(Iterable<NoticeModel> items) {
    final list = items.toList()
      ..sort((a, b) {
        // Pinned notice first, then newest-first by date.
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return list;
  }

  @override
  Future<List<NoticeModel>> getNotices() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_notices);
  }

  @override
  Future<NoticeModel> addNotice({
    required String title,
    required String description,
  }) async {
    final model = NoticeModel(
      id: _nextId(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    _notices.add(model);
    return model;
  }

  @override
  Future<NoticeModel> updateNotice({
    required String id,
    required String title,
    required String description,
  }) async {
    final index = _notices.indexWhere((n) => n.id == id);
    if (index == -1) {
      throw ServerException(message: 'Notice not found');
    }
    final updated =
        _notices[index].copyWith(title: title, description: description);
    _notices[index] = updated;
    return updated;
  }

  @override
  Future<void> setPinned({required String id, required bool pinned}) async {
    final index = _notices.indexWhere((n) => n.id == id);
    if (index == -1) {
      throw ServerException(message: 'Notice not found');
    }
    // Only one notice may be pinned at a time.
    if (pinned) {
      for (var i = 0; i < _notices.length; i++) {
        if (_notices[i].pinned) {
          _notices[i] = _notices[i].copyWith(pinned: false);
        }
      }
    }
    _notices[index] = _notices[index].copyWith(pinned: pinned);
  }

  @override
  Future<void> deleteNotice(String id) async {
    _notices.removeWhere((n) => n.id == id);
  }
}
