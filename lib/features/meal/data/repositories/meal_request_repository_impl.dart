import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/errors/exceptions.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/features/meal/data/datasources/interfaces/meal_request_data_source.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';
import 'package:mess_pilot/features/meal/domain/repositories/meal_request_repository.dart';

@LazySingleton(as: MealRequestRepository)
class MealRequestRepositoryImpl implements MealRequestRepository {
  const MealRequestRepositoryImpl(this._dataSource);

  final MealRequestDataSource _dataSource;

  @override
  ResultFuture<MealRequestOverviewEntity> getRequests() => _guard(() async => (await _dataSource.getRequests()).toEntity());

  @override
  ResultVoid createRequest(MealRequestDraft draft) => _guard(() => _dataSource.createRequest(draft));

  @override
  ResultVoid updateRequest({required String id, required MealRequestDraft draft}) => _guard(() => _dataSource.updateRequest(id: id, draft: draft));

  @override
  ResultVoid deleteRequest(String id) => _guard(() => _dataSource.deleteRequest(id));

  @override
  ResultVoid saveSelection({required String id, required double breakfast, required double lunch, required double dinner}) =>
      _guard(() => _dataSource.saveSelection(id: id, breakfast: breakfast, lunch: lunch, dinner: dinner));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(data: await action());
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
      return Result.failure(error: ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }
}
