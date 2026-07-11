import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/meal/data/datasources/interfaces/meal_admin_data_source.dart';
import 'package:clean_boilerplate/features/meal/data/models/meal_admin_model.dart';

@LazySingleton(as: MealAdminDataSource)
class MealAdminRemoteDataSourceImpl implements MealAdminDataSource {
  final ApiClient _apiClient;

  MealAdminRemoteDataSourceImpl(this._apiClient);

  @override
  Future<MealAdminModel> getAdminData() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.mealAdminDataEndpoint);
    return MealAdminModel.fromJson(response.data!);
  }

  @override
  Future<MealAdminModel> addMealForAll({required DateTime date, required double breakfast, required double lunch, required double dinner}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.addMealBulkEndpoint,
      data: {
        'date': _date(date),
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
      },
    );
    return MealAdminModel.fromJson(response.data!);
  }

  @override
  Future<MealAdminModel> saveMemberMeal({required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.addMealEndpoint,
      data: {
        'member_id': int.parse(memberId),
        'date': _date(date),
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
      },
    );
    return MealAdminModel.fromJson(response.data!);
  }

  @override
  Future<MealAdminModel> updateMemberMeal({required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner}) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      AppConstants.addMealEndpoint,
      data: {
        'member_id': int.parse(memberId),
        'date': _date(date),
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
      },
    );
    return MealAdminModel.fromJson(response.data!);
  }

  @override
  Future<MealAdminModel> deleteMemberMeal({required String memberId, required DateTime date}) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      AppConstants.addMealEndpoint,
      data: {
        'member_id': int.parse(memberId),
        'date': _date(date),
      },
    );
    return MealAdminModel.fromJson(response.data!);
  }

  String _date(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
