import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';

part 'cost_event.freezed.dart';

/// Cost (bazar) events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class CostEvent with _$CostEvent {
  /// Initial load. [isAdmin] gates add / edit / delete and the entry tab.
  const factory CostEvent.started({required bool isAdmin}) = CostStarted;

  /// Reload the list.
  const factory CostEvent.refresh() = CostRefresh;

  /// Record a bazar entry for one member.
  const factory CostEvent.add({required String personId, required DateTime date, required List<CostItemEntity> items}) = CostAdd;

  /// Edit an existing bazar entry.
  const factory CostEvent.update({required String id, required String personId, required DateTime date, required List<CostItemEntity> items}) = CostUpdate;

  /// Remove a bazar entry.
  const factory CostEvent.delete(String id) = CostDelete;
}
