import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

part 'poll_event.freezed.dart';

/// Poll screen events. Actions carry an optional [done] completer so the UI can
/// show the outcome (snack bar / form errors) once the action and reload finish.
@Freezed(toJson: false, fromJson: false)
class PollEvent with _$PollEvent {
  const factory PollEvent.started() = PollStarted;

  const factory PollEvent.refresh({Completer<Failure?>? done}) = PollRefresh;

  const factory PollEvent.create({required PollDraft draft, Completer<Failure?>? done}) = PollCreate;

  const factory PollEvent.update({required String id, required PollDraft draft, @Default(true) bool updateOptions, Completer<Failure?>? done}) = PollUpdate;

  const factory PollEvent.vote({required String id, required List<String> optionIds, Completer<Failure?>? done}) = PollVote;

  const factory PollEvent.withdrawVote({required String id, Completer<Failure?>? done}) = PollWithdrawVote;

  const factory PollEvent.toggleClosed({required String id, required bool closed, Completer<Failure?>? done}) = PollToggleClosed;

  const factory PollEvent.delete({required String id, Completer<Failure?>? done}) = PollDelete;
}
