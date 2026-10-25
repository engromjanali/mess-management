import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_overview_entity.dart';

part 'season_state.freezed.dart';

/// Season management states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class SeasonState with _$SeasonState {
  /// Before the first load.
  const factory SeasonState.initial() = SeasonInitial;

  /// Loading for the first time.
  const factory SeasonState.loading() = SeasonLoading;

  /// Seasons loaded. [busy] is true while a refresh or change runs — the list
  /// stays shown with progress and the actions are disabled.
  const factory SeasonState.loaded({required SeasonOverviewEntity overview, @Default(false) bool busy}) = SeasonLoaded;

  /// The first load failed (nothing to show yet).
  const factory SeasonState.error(String message) = SeasonError;
}
