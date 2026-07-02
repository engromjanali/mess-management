import 'package:clean_boilerplate/config/util/result.dart' hide Failure;
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';

Failure mapErrorToFailure(Object error) {
  if (error is Failure) return error;

  if (error is UnauthorizedException) {
    return AuthenticationFailure(message: error.message, statusCode: error.statusCode);
  }
  if (error is NoInternetException) {
    return NetworkFailure(message: error.message);
  }
  if (error is RequestTimeoutException) {
    return NetworkFailure(message: error.message);
  }
  if (error is NetworkException) {
    return NetworkFailure(message: error.message);
  }
  if (error is CacheException) {
    return CacheFailure(message: error.message);
  }
  if (error is ServerException) {
    return ServerFailure(message: error.message, statusCode: error.statusCode);
  }
  return ServerFailure(message: 'An unexpected error occurred: $error');
}


ResultFuture<T> guardResult<T>(Future<T> Function() action) async {
  try {
    return Result.success(data: await action());
  } catch (error, stackTrace) {
    final failure = mapErrorToFailure(error);
    return Result.failure(error: failure, message: failure.message, stackTrace: stackTrace);
  }
}
