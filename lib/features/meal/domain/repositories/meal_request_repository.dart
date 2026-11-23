import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';

abstract class MealRequestRepository {
  ResultFuture<MealRequestOverviewEntity> getRequests();

  ResultVoid createRequest(MealRequestDraft draft);

  ResultVoid updateRequest({required String id, required MealRequestDraft draft});

  ResultVoid deleteRequest(String id);

  ResultVoid saveSelection({required String id, required double breakfast, required double lunch, required double dinner});
}
