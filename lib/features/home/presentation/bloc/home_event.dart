import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_event.freezed.dart';

/// Home events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class HomeEvent with _$HomeEvent {
  /// Initial load of the dashboard.
  const factory HomeEvent.loadDashboard() = LoadDashboard;

  /// Pull-to-refresh of the dashboard.
  const factory HomeEvent.refreshDashboard() = RefreshDashboard;
}
