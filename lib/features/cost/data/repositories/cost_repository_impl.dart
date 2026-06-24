import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/cost_entity.dart';
import '../../domain/repositories/cost_repository.dart';
import '../datasources/interfaces/cost_data_source.dart';

/// Concrete [CostRepository] in the data layer.
@LazySingleton(as: CostRepository)
class CostRepositoryImpl implements CostRepository {
  final CostDataSource _dataSource;

  CostRepositoryImpl(this._dataSource);

  @override
  ResultFuture<List<CostMemberEntity>> getMembers() => _guard(() async {
        final models = await _dataSource.getMembers();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<CostEntity>> getCosts() => _guard(() async {
        final models = await _dataSource.getCosts();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<CostEntity> addCost({
    required String personId,
    required DateTime date,
    required List<CostItemEntity> items,
  }) =>
      _guard(() async {
        final model = await _dataSource.addCost(
          personId: personId,
          date: date,
          items: items,
        );
        return model.toEntity();
      });

  @override
  ResultFuture<CostEntity> updateCost({
    required String id,
    required String personId,
    required DateTime date,
    required List<CostItemEntity> items,
  }) =>
      _guard(() async {
        final model = await _dataSource.updateCost(
          id: id,
          personId: personId,
          date: date,
          items: items,
        );
        return model.toEntity();
      });

  @override
  ResultVoid deleteCost(String id) => _guard(() => _dataSource.deleteCost(id));

  /// Shared try/catch mapping data-layer exceptions to domain failures.
  ResultFuture<T> _guard<T>(Future<T> Function() action) async {
    try {
      final data = await action();
      return Result.success(data: data);
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
