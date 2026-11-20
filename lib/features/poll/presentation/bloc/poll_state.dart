import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

part 'poll_state.freezed.dart';

@Freezed(toJson: false, fromJson: false)
class PollState with _$PollState {
  const factory PollState.initial() = PollInitial;

  const factory PollState.loading() = PollLoading;

  /// [busy] is true while a refresh / action runs; the list stays on screen.
  const factory PollState.loaded({required List<PollEntity> polls, required bool canManage, @Default(false) bool busy}) = PollLoaded;

  const factory PollState.error(String message) = PollError;
}
