import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';

part 'season_event.freezed.dart';

/// Season management events. Runtime-only, so no JSON serialization.
///
/// Actions carry an optional [done] completer, completed with `null` on
/// success or the [Failure] — so the caller can show the outcome (a snack bar,
/// or field errors in the form) once the action and the reload finish.
@Freezed(toJson: false, fromJson: false)
class SeasonEvent with _$SeasonEvent {
  /// Initial load.
  const factory SeasonEvent.started() = SeasonStarted;

  /// Reload, keeping the current list on screen.
  const factory SeasonEvent.refresh({Completer<Failure?>? done}) = SeasonRefresh;

  /// Create a season from [sourceSeasonId]'s members.
  const factory SeasonEvent.create({required String name, required DateTime startDate, required String sourceSeasonId, Completer<Failure?>? done}) = SeasonCreate;

  /// Rename a season or move its dates; a null [endDate] reopens it.
  const factory SeasonEvent.update({required String id, required String name, required DateTime startDate, DateTime? endDate, Completer<Failure?>? done}) = SeasonUpdate;

  /// End a running season today.
  const factory SeasonEvent.end(String id, {Completer<Failure?>? done}) = SeasonEnd;

  /// Disable or enable a season.
  const factory SeasonEvent.setDisabled({required String id, required bool disabled, Completer<Failure?>? done}) = SeasonSetDisabled;

  /// Work in another season.
  const factory SeasonEvent.switchTo(String id, {Completer<Failure?>? done}) = SeasonSwitchTo;

  /// Delete a season with all its data.
  const factory SeasonEvent.delete(String id, {Completer<Failure?>? done}) = SeasonDelete;

  /// Change the auto-create setting; null fields stay unchanged.
  const factory SeasonEvent.setAutoCreate({bool? enabled, int? day, Completer<Failure?>? done}) = SeasonSetAutoCreate;
}
