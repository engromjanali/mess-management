import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// A generic result wrapper that encapsulates success/failure states
/// Adapted from flutter_pos to work with Dio instead of HTTP
sealed class Result<T> extends Equatable {
  const Result();

  @override
  List<Object?> get props => [];

  factory Result.success({required T data, String? title, String? message, String? state}) = Success<T>;

  factory Result.failure({required Object error, String? title, String? message, String? state, StackTrace? stackTrace}) = Failure<T>;

  /// Creates a Result from a Dio response with proper error handling
  /// If parser is not provided, returns the raw response data as data
  factory Result.fromDioResponse({required Response response, T Function(Map<String, dynamic>?)? parser}) {
    try {
      final isSuccess = response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;

      if (isSuccess) {
        final T parsedData;

        if (parser != null) {
          parsedData = parser(response.data is Map<String, dynamic> ? response.data as Map<String, dynamic>? : null);
        } else {
          parsedData = response.data as T;
        }

        return Result.success(title: 'HTTP Success', message: response.statusMessage, state: response.statusCode.toString(), data: parsedData);
      } else {
        return Result.failure(title: 'HTTP Error', message: response.statusMessage, state: response.statusCode.toString(), error: 'HTTP Error with status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      return Result.failure(title: 'Parse Error', message: 'Failed to parse response body with parser type of $T', error: e, stackTrace: stackTrace);
    }
  }

  String? get title => switch (this) {
    Success(title: final title) => title,
    Failure(title: final title) => title,
  };

  String? get message => switch (this) {
    Success(message: final message) => message,
    Failure(message: final message) => message,
  };

  String? get state => switch (this) {
    Success(state: final state) => state,
    Failure(state: final state) => state,
  };

  T? get data => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };

  Object? get error => switch (this) {
    Success() => null,
    Failure(error: final error) => error,
  };

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  R? onSuccess<R>(R Function(Success<T> success) success) => switch (this) {
    Success() => success(this as Success<T>),
    Failure() => null,
  };

  R? onFailure<R>(R Function(Failure<T> failure) failure) => switch (this) {
    Success() => null,
    Failure() => failure(this as Failure<T>),
  };

  R when<R>({required R Function(Success<T> success) success, required R Function(Failure<T> failure) failure}) {
    return switch (this) {
      Success() => success(this as Success<T>),
      Failure() => failure(this as Failure<T>),
    };
  }
}

final class Success<T> extends Result<T> {
  @override
  final String? title;
  @override
  final String? message;
  @override
  final String? state;
  @override
  final T data;

  const Success({required this.data, this.title, this.message, this.state});

  @override
  List<Object?> get props => [data, title, message, state];
}

final class Failure<T> extends Result<T> {
  @override
  final String? title;
  @override
  final String? message;
  @override
  final String? state;
  @override
  final Object error;
  final StackTrace? stackTrace;

  const Failure({required this.error, this.title, this.message, this.state, this.stackTrace});

  @override
  List<Object?> get props => [error, title, message, state, stackTrace];
}

/// Type aliases for convenience
typedef ResultFuture<T> = Future<Result<T>>;
typedef ResultVoid = Future<Result<void>>;
