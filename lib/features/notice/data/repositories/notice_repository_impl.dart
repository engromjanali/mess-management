import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notice_entity.dart';
import '../../domain/repositories/notice_repository.dart';
import '../datasources/interfaces/notice_data_source.dart';

/// Concrete [NoticeRepository] in the data layer.
@LazySingleton(as: NoticeRepository)
class NoticeRepositoryImpl implements NoticeRepository {
  final NoticeDataSource _dataSource;

  NoticeRepositoryImpl(this._dataSource);

  @override
  ResultFuture<List<NoticeEntity>> getNotices() => _guard(() async {
        final models = await _dataSource.getNotices();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  ResultFuture<NoticeEntity> addNotice({
    required String title,
    required String description,
  }) =>
      _guard(() async {
        final model = await _dataSource.addNotice(
          title: title,
          description: description,
        );
        return model.toEntity();
      });

  @override
  ResultFuture<NoticeEntity> updateNotice({
    required String id,
    required String title,
    required String description,
  }) =>
      _guard(() async {
        final model = await _dataSource.updateNotice(
          id: id,
          title: title,
          description: description,
        );
        return model.toEntity();
      });

  @override
  ResultVoid setPinned({required String id, required bool pinned}) =>
      _guard(() => _dataSource.setPinned(id: id, pinned: pinned));

  @override
  ResultVoid deleteNotice(String id) =>
      _guard(() => _dataSource.deleteNotice(id));

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
