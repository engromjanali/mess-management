import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/meal_member_entity.dart';
import '../../domain/repositories/meal_admin_repository.dart';
import '../datasources/interfaces/meal_admin_data_source.dart';

/// Concrete [MealAdminRepository] in the data layer.
@LazySingleton(as: MealAdminRepository)
class MealAdminRepositoryImpl implements MealAdminRepository {
  final MealAdminDataSource _dataSource;

  MealAdminRepositoryImpl(this._dataSource);

  @override
  ResultFuture<MealAdminEntity> getAdminData() =>
      _guard(() => _dataSource.getAdminData());

  @override
  ResultFuture<MealAdminEntity> addMealForAll({
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) =>
      _guard(
        () => _dataSource.addMealForAll(
          date: date,
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
        ),
      );

  @override
  ResultFuture<MealAdminEntity> saveMemberMeal({
    required String memberId,
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) =>
      _guard(
        () => _dataSource.saveMemberMeal(
          memberId: memberId,
          date: date,
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
        ),
      );

  @override
  ResultFuture<MealAdminEntity> deleteMemberMeal({
    required String memberId,
    required DateTime date,
  }) =>
      _guard(
        () => _dataSource.deleteMemberMeal(memberId: memberId, date: date),
      );

  /// Shared try/catch that maps data-layer exceptions to domain failures.
  ResultFuture<MealAdminEntity> _guard(
    Future<dynamic> Function() action,
  ) async {
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
      return Result.failure(
        error: ServerFailure(
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }
}
