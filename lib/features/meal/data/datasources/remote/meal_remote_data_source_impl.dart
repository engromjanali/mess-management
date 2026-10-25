import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/meal/data/datasources/interfaces/meal_data_source.dart';
import 'package:clean_boilerplate/features/meal/data/models/meal_model.dart';

/// The signed-in user's own meals in their active season (`/api/v1/user/meals`).
@LazySingleton(as: MealDataSource)
class MealRemoteDataSourceImpl implements MealDataSource {
  final ApiClient _apiClient;

  MealRemoteDataSourceImpl(this._apiClient);

  @override
  Future<MealOverviewModel> getMealOverview() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.myMealsEndpoint);
    return MealOverviewModel.fromJson(response.data!);
  }
}
