import 'package:mess_pilot/features/meal/data/models/meal_request_model.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';

abstract class MealRequestDataSource {
  Future<MealRequestOverviewModel> getRequests();

  Future<void> createRequest(MealRequestDraft draft);

  Future<void> updateRequest({required String id, required MealRequestDraft draft});

  Future<void> deleteRequest(String id);

  Future<void> saveSelection({required String id, required double breakfast, required double lunch, required double dinner});
}
