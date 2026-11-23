import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/meal/data/datasources/interfaces/meal_request_data_source.dart';
import 'package:mess_pilot/features/meal/data/models/meal_request_model.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';

@LazySingleton(as: MealRequestDataSource)
class MealRequestRemoteDataSourceImpl implements MealRequestDataSource {
  const MealRequestRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  static final Options _private = Options(extra: {'sensitive': true});

  @override
  Future<MealRequestOverviewModel> getRequests() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.mealRequestsEndpoint, options: _private);
    return MealRequestOverviewModel.fromJson(response.data!);
  }

  @override
  Future<void> createRequest(MealRequestDraft draft) async {
    await _apiClient.post<Map<String, dynamic>>(
      AppConstants.adminMealRequestsEndpoint,
      data: {
        'date': _date(draft.date),
        'title': draft.title,
        'description': draft.description,
        'end_at': draft.endAt.toIso8601String(),
      },
      options: _private,
    );
  }

  @override
  Future<void> updateRequest({required String id, required MealRequestDraft draft}) async {
    await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.adminMealRequestsEndpoint}/$id',
      data: {
        'date': _date(draft.date),
        'title': draft.title,
        'description': draft.description,
        'end_at': draft.endAt.toIso8601String(),
      },
      options: _private,
    );
  }

  @override
  Future<void> deleteRequest(String id) async {
    await _apiClient.delete<Map<String, dynamic>>('${AppConstants.adminMealRequestsEndpoint}/$id', options: _private);
  }

  @override
  Future<void> saveSelection({required String id, required double breakfast, required double lunch, required double dinner}) async {
    await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.mealRequestsEndpoint}/$id',
      data: {'breakfast': breakfast, 'lunch': lunch, 'dinner': dinner},
      options: _private,
    );
  }

  String _date(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
