import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';

part 'notice_event.freezed.dart';

/// Notice events. Runtime-only, so no JSON serialization.
///
/// Actions carry an optional [done] completer, completed with `null` on
/// success or the [Failure] — so the caller can show the outcome (a snack bar,
/// or field errors in the form) once the action and the reload finish.
@Freezed(toJson: false, fromJson: false)
class NoticeEvent with _$NoticeEvent {
  /// Initial load. [isAdmin] gates publish / edit / pin / delete.
  const factory NoticeEvent.started({required bool isAdmin}) = NoticeStarted;

  /// Reload the list, keeping the current one on screen.
  const factory NoticeEvent.refresh({Completer<Failure?>? done}) = NoticeRefresh;

  /// Publish a new notice.
  const factory NoticeEvent.add({required String title, required String description, Completer<Failure?>? done}) = NoticeAdd;

  /// Edit an existing notice.
  const factory NoticeEvent.update({required String id, required String title, required String description, Completer<Failure?>? done}) = NoticeUpdate;

  /// Pin or unpin a notice (pinning one unpins any other).
  const factory NoticeEvent.togglePin({required String id, required bool pinned, Completer<Failure?>? done}) = NoticeTogglePin;

  /// Remove a notice.
  const factory NoticeEvent.delete(String id, {Completer<Failure?>? done}) = NoticeDelete;
}
