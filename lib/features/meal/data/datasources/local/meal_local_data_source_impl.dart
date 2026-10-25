import 'package:clean_boilerplate/features/meal/data/models/meal_model.dart';
import 'package:clean_boilerplate/features/meal/data/datasources/interfaces/meal_data_source.dart';

/// Local, in-memory mock meal source.
///
/// Seeds a couple of weeks of representative history so the meal screen is
/// fully previewable without a backend. Not bound: the app uses
/// `MealRemoteDataSourceImpl`. Move its `@LazySingleton(as: MealDataSource)`
/// here to preview offline.
class MealLocalDataSourceImpl implements MealDataSource {
  static const double _mealRate = 62.5;

  late final List<MealModel> _days = _seed();

  /// Deterministic two-week history (no randomness, stable across rebuilds).
  List<MealModel> _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Repeating but realistic B/L/D pattern over the past 14 days.
    const breakfastPattern = [0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0];
    const lunchPattern = [1.0, 1.0, 1.5, 1.0, 1.0, 0.0, 1.0];
    const dinnerPattern = [1.0, 1.0, 1.0, 1.0, 1.5, 1.0, 1.0];

    return List<MealModel>.generate(14, (i) {
      // i = 0 → 13 days ago, i = 13 → today.
      final date = today.subtract(Duration(days: 13 - i));
      final p = i % 7;
      return MealModel(date: date, breakfast: breakfastPattern[p], lunch: lunchPattern[p], dinner: dinnerPattern[p]);
    });
  }

  @override
  Future<MealOverviewModel> getMealOverview() async {
    // Simulate IO latency so loading + refresh states are visible.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _overview();
  }

  MealOverviewModel _overview() => MealOverviewModel(userName: 'Romjan', mealRate: _mealRate, days: List<MealModel>.unmodifiable(_days));
}
