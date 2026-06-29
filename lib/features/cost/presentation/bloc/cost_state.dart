import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';

part 'cost_state.freezed.dart';

/// Cost (bazar) states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class CostState with _$CostState {
  /// Before the first load.
  const factory CostState.initial() = CostInitial;

  /// The list is loading for the first time.
  const factory CostState.loading() = CostLoading;

  /// Entries loaded (or just mutated). [members] backs the entry person
  /// picker (empty for non-admins). [isAdmin] gates add / edit / delete.
  /// [saving] flags an in-flight mutation; [justSaved] briefly flags a
  /// successful add / update so the UI can react (e.g. jump to the list).
  const factory CostState.loaded({required List<CostEntity> costs, required List<CostMemberEntity> members, required bool isAdmin, @Default(false) bool saving, @Default(false) bool justSaved}) =
      CostLoaded;

  /// Loading failed.
  const factory CostState.error(String message) = CostError;
}
