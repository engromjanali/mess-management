import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';

part 'notice_state.freezed.dart';

/// Notice states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class NoticeState with _$NoticeState {
  /// Before the first load.
  const factory NoticeState.initial() = NoticeInitial;

  /// The list is loading for the first time.
  const factory NoticeState.loading() = NoticeLoading;

  /// Notices loaded (or just mutated). [isAdmin] gates add / edit / delete.
  /// [saving] flags an in-flight mutation.
  const factory NoticeState.loaded({required List<NoticeEntity> notices, required bool isAdmin, @Default(false) bool saving}) = NoticeLoaded;

  /// Loading failed.
  const factory NoticeState.error(String message) = NoticeError;
}
