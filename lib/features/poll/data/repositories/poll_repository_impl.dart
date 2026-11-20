import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/errors/exceptions.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/features/poll/data/datasources/interfaces/poll_data_source.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/domain/repositories/poll_repository.dart';

/// Concrete [PollRepository] in the data layer.
@LazySingleton(as: PollRepository)
class PollRepositoryImpl implements PollRepository {
  const PollRepositoryImpl(this._dataSource);

  final PollDataSource _dataSource;

  @override
  ResultFuture<PollOverviewEntity> getPolls({int page = 1, bool includePast = true}) => _guard(
        () async => (await _dataSource.getPolls(page: page, includePast: includePast)).toEntity(),
      );

  @override
  ResultFuture<PollEntity> getPoll(String id) => _guard(() async => (await _dataSource.getPoll(id)).toEntity());

  @override
  ResultFuture<PollEntity> createPoll(PollDraft draft) => _guard(() async => (await _dataSource.createPoll(draft)).toEntity());

  @override
  ResultFuture<PollEntity> updatePoll({required String id, required PollDraft draft, bool updateOptions = true}) => _guard(
        () async => (await _dataSource.updatePoll(id: id, draft: draft, updateOptions: updateOptions)).toEntity(),
      );

  @override
  ResultFuture<PollEntity> vote({required String id, required List<String> optionIds}) => _guard(
        () async => (await _dataSource.vote(id: id, optionIds: optionIds)).toEntity(),
      );

  @override
  ResultFuture<PollEntity> withdrawVote(String id) => _guard(() async => (await _dataSource.withdrawVote(id)).toEntity());

  @override
  ResultFuture<PollEntity> setClosed({required String id, required bool closed}) => _guard(
        () async => (await _dataSource.setClosed(id: id, closed: closed)).toEntity(),
      );

  @override
  ResultVoid deletePoll(String id) => _guard(() => _dataSource.deletePoll(id));

  /// Shared try/catch mapping data-layer exceptions to domain failures.
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
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
      return Result.failure(error: AuthenticationFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Result.failure(error: ServerFailure(message: e.message, statusCode: e.statusCode, fieldErrors: e.fieldErrors));
    } catch (e) {
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}
