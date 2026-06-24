import 'package:freezed_annotation/freezed_annotation.dart';

part 'notice_event.freezed.dart';

/// Notice events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class NoticeEvent with _$NoticeEvent {
  /// Initial load. [isAdmin] gates add / edit / delete.
  const factory NoticeEvent.started({required bool isAdmin}) = NoticeStarted;

  /// Reload the list.
  const factory NoticeEvent.refresh() = NoticeRefresh;

  /// Publish a new notice.
  const factory NoticeEvent.add({
    required String title,
    required String description,
  }) = NoticeAdd;

  /// Edit an existing notice.
  const factory NoticeEvent.update({
    required String id,
    required String title,
    required String description,
  }) = NoticeUpdate;

  /// Pin or unpin a notice (pinning one unpins any other).
  const factory NoticeEvent.togglePin({
    required String id,
    required bool pinned,
  }) = NoticeTogglePin;

  /// Remove a notice.
  const factory NoticeEvent.delete(String id) = NoticeDelete;
}
