import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/features/season/data/datasources/interfaces/season_data_source.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_overview_entity.dart';
import 'package:clean_boilerplate/features/season/domain/repositories/season_repository.dart';

/// Concrete [SeasonRepository] in the data layer.
@LazySingleton(as: SeasonRepository)
class SeasonRepositoryImpl implements SeasonRepository {
  final SeasonDataSource _dataSource;

  SeasonRepositoryImpl(this._dataSource);

  @override
  ResultFuture<SeasonOverviewEntity> getSeasons() => _guard(() async => (await _dataSource.getSeasons()).toEntity());

  @override
  ResultVoid createSeason({required String name, required DateTime startDate, required String sourceSeasonId}) =>
      _guard(() => _dataSource.createSeason(name: name, startDate: startDate, sourceSeasonId: sourceSeasonId));

  @override
  ResultVoid updateSeason({required String id, required String name, required DateTime startDate, DateTime? endDate}) =>
      _guard(() => _dataSource.updateSeason(id: id, name: name, startDate: startDate, endDate: endDate));

  @override
  ResultVoid endSeason(String id) => _guard(() => _dataSource.endSeason(id));

  @override
  ResultVoid setDisabled({required String id, required bool disabled}) => _guard(() => _dataSource.setDisabled(id: id, disabled: disabled));

  @override
  ResultVoid switchSeason(String id) => _guard(() => _dataSource.switchSeason(id));

  @override
  ResultVoid deleteSeason(String id) => _guard(() => _dataSource.deleteSeason(id));

  @override
  ResultVoid updateAutoCreate({bool? enabled, int? day}) => _guard(() => _dataSource.updateAutoCreate(enabled: enabled, day: day));

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
    } on UnauthorizedException catch (e) {
      return Result.failure(
        error: AuthenticationFailure(message: e.message, statusCode: e.statusCode),
      );
    } on ServerException catch (e) {
      return Result.failure(
        error: ServerFailure(message: e.message, statusCode: e.statusCode, fieldErrors: e.fieldErrors),
      );
    } catch (e) {
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}
