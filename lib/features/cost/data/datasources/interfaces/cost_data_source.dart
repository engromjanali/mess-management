import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/data/models/cost_model.dart';

/// Contract for any source that can provide & mutate Cost/cost entries.
abstract class CostDataSource {
  Future<List<CostMemberModel>> getMembers();

  Future<List<CostModel>> getCosts();

  Future<CostModel> addCost({required String personId, required DateTime date, required List<CostItemEntity> items});

  Future<CostModel> updateCost({required String id, required String personId, required DateTime date, required List<CostItemEntity> items});

  Future<void> deleteCost(String id);
}
