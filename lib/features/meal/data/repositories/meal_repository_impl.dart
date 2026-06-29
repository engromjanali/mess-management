import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_entity.dart';
import 'package:clean_boilerplate/features/meal/domain/repositories/meal_repository.dart';
import 'package:clean_boilerplate/features/meal/data/datasources/interfaces/meal_data_source.dart';

/// Concrete [MealRepository] in the data layer.
@LazySingleton(as: MealRepository)
class MealRepositoryImpl implements MealRepository {
  final MealDataSource _dataSource;

  MealRepositoryImpl(this._dataSource);

  @override
  ResultFuture<MealOverviewEntity> getMealOverview() => _guard(() => _dataSource.getMealOverview());

  @override
  ResultFuture<MealOverviewEntity> updateMeal({required DateTime date, required double breakfast, required double lunch, required double dinner}) =>
      _guard(() => _dataSource.updateMeal(date: date, breakfast: breakfast, lunch: lunch, dinner: dinner));

  /// Shared try/catch that maps data-layer exceptions to domain failures.
  ResultFuture<MealOverviewEntity> _guard(Future<dynamic> Function() action) async {
    try {
      final model = await action();
      return Result.success(data: model.toEntity());
    } on NoInternetException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on RequestTimeoutException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on NetworkException catch (e) {
      return Result.failure(error: NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Result.failure(
        error: ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}
