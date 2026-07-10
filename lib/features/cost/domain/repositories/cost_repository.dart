import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';

/// Cost (Cost) repository contract (abstraction in the domain layer).
abstract class CostRepository {
  /// The roster of members a cost entry can be recorded for.
  ResultFuture<List<CostMemberEntity>> getMembers();

  /// Every Cost/cost entry (newest first).
  ResultFuture<List<CostEntity>> getCosts();

  /// Records a Cost/cost entry for one member.
  ResultFuture<CostEntity> addCost({required String personId, required DateTime date, required List<CostItemEntity> items});

  /// Edits an existing Cost/cost entry.
  ResultFuture<CostEntity> updateCost({required String id, required String personId, required DateTime date, required List<CostItemEntity> items});

  /// Removes a Cost/cost entry.
  ResultVoid deleteCost(String id);
}
