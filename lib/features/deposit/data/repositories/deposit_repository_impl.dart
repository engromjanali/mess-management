import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/deposit_entity.dart';
import '../../domain/repositories/deposit_repository.dart';
import '../datasources/interfaces/deposit_data_source.dart';

/// Concrete [DepositRepository] in the data layer.
@LazySingleton(as: DepositRepository)
class DepositRepositoryImpl implements DepositRepository {
  final DepositDataSource _dataSource;

  DepositRepositoryImpl(this._dataSource);

  @override
  ResultFuture<List<DepositMemberEntity>> getMembers() => _guard(() async {
        final models = await _dataSource.getMembers();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<DepositEntity>> getAllDeposits() => _guard(() async {
        final models = await _dataSource.getAllDeposits();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<DepositEntity>> getMemberDeposits(String memberId) =>
      _guard(() async {
        final models = await _dataSource.getMemberDeposits(memberId);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<DepositEntity>> getDepositsByDate(DateTime date) =>
      _guard(() async {
        final models = await _dataSource.getDepositsByDate(date);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<DepositEntity>> getDepositsInRange(
    DateTime start,
    DateTime end,
  ) =>
      _guard(() async {
        final models = await _dataSource.getDepositsInRange(start, end);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<List<DepositEntity>> getMyDeposits() => _guard(() async {
        final models = await _dataSource.getMyDeposits();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<DepositEntity> addDeposit({
    required String memberId,
    required double amount,
    required DateTime date,
    String? note,
  }) =>
      _guard(() async {
        final model = await _dataSource.addDeposit(
          memberId: memberId,
          amount: amount,
          date: date,
          note: note,
        );
        return model.toEntity();
      });

  @override
  ResultFuture<DepositEntity> updateDeposit({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  }) =>
      _guard(() async {
        final model = await _dataSource.updateDeposit(
          id: id,
          amount: amount,
          date: date,
          note: note,
        );
        return model.toEntity();
      });

  @override
  ResultVoid deleteDeposit(String id) =>
      _guard(() => _dataSource.deleteDeposit(id));

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
