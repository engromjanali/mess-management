import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/home/domain/entities/dashboard_entity.dart';

part 'home_state.freezed.dart';

/// Home states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class HomeState with _$HomeState {
  /// Before any load has started.
  const factory HomeState.initial() = HomeInitial;

  /// Dashboard is loading for the first time.
  const factory HomeState.loading() = HomeLoading;

  /// Dashboard loaded successfully.
  const factory HomeState.loaded(DashboardEntity dashboard) = HomeLoaded;

  /// Loading failed.
  const factory HomeState.error(String message) = HomeError;
}
