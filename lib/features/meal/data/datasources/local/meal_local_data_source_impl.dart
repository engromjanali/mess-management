import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/features/meal/data/models/meal_model.dart';
import 'package:clean_boilerplate/features/meal/data/datasources/interfaces/meal_data_source.dart';

/// Local, in-memory mock meal source.
///
/// Seeds a couple of weeks of representative history so the meal screen is
/// fully previewable without a backend, and keeps edits in memory for the
/// session. Swap this binding for a remote implementation later — the
/// repository and presentation layers won't change.
@LazySingleton(as: MealDataSource)
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
      return MealModel(
        date: date,
        breakfast: breakfastPattern[p],
        lunch: lunchPattern[p],
        dinner: dinnerPattern[p],
      );
    });
  }

  @override
  Future<MealOverviewModel> getMealOverview() async {
    // Simulate IO latency so loading + refresh states are visible.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _overview();
  }

  @override
  Future<MealOverviewModel> updateMeal({
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) async {
    final key = DateTime(date.year, date.month, date.day);
    final index = _days.indexWhere(
      (d) =>
          d.date.year == key.year &&
          d.date.month == key.month &&
          d.date.day == key.day,
    );

    final updated = MealModel(
      date: key,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
    );

    if (index == -1) {
      _days.add(updated);
    } else {
      _days[index] = updated;
    }

    // Edits resolve instantly for a snappy stepper experience.
    return _overview();
  }

  MealOverviewModel _overview() => MealOverviewModel(
        userName: 'Romjan',
        mealRate: _mealRate,
        days: List<MealModel>.unmodifiable(_days),
      );
}
