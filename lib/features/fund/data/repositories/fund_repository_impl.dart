import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/fund_entity.dart';
import '../../domain/repositories/fund_repository.dart';
import '../datasources/interfaces/fund_data_source.dart';

/// Concrete [FundRepository] in the data layer.
@LazySingleton(as: FundRepository)
class FundRepositoryImpl implements FundRepository {
  final FundDataSource _dataSource;

  FundRepositoryImpl(this._dataSource);

  @override
  ResultFuture<List<FundEntity>> getAllFunds() => _guard(() async {
        final models = await _dataSource.getAllFunds();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<FundEntity>> getFundsByDate(DateTime date) =>
      _guard(() async {
        final models = await _dataSource.getFundsByDate(date);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<FundEntity>> getFundsInRange(
    DateTime start,
    DateTime end,
  ) =>
      _guard(() async {
        final models = await _dataSource.getFundsInRange(start, end);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<FundEntity> addFund({
    required double amount,
    required DateTime date,
    String? note,
  }) =>
      _guard(() async {
        final model =
            await _dataSource.addFund(amount: amount, date: date, note: note);
        return model.toEntity();
      });

  @override
  ResultFuture<FundEntity> updateFund({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  }) =>
      _guard(() async {
        final model = await _dataSource.updateFund(
          id: id,
          amount: amount,
          date: date,
          note: note,
        );
        return model.toEntity();
      });

  @override
  ResultVoid deleteFund(String id) => _guard(() => _dataSource.deleteFund(id));

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
