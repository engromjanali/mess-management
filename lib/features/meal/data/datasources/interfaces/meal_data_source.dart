import 'package:clean_boilerplate/features/meal/data/models/meal_model.dart';

/// Contract for any source that can provide the user's meal data.
abstract class MealDataSource {
  Future<MealOverviewModel> getMealOverview();
}
