import 'package:dio/dio.dart';

/// Exception classes
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});
}

class NoInternetException implements Exception {
  final String message;

  NoInternetException({required this.message});
}

class RequestTimeoutException implements Exception {
  final String message;

  RequestTimeoutException({required this.message});
}

class UnauthorizedException implements Exception {
  final String message;
  final int statusCode;

  UnauthorizedException({required this.message, this.statusCode = 401});
}

/// Extension to convert DioException to appropriate exceptions
extension DioExceptionX on DioException {
  Exception toAppException() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RequestTimeoutException(message: 'Request timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        if (statusCode == 401) {
          return UnauthorizedException(message: response?.data['message'] ?? 'Unauthorized access', statusCode: statusCode!);
        }
        return ServerException(message: _extractErrorMessage(response?.data), statusCode: statusCode);
      case DioExceptionType.cancel:
        return ServerException(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return NoInternetException(message: 'No internet connection. Please check your network.');
      default:
        return ServerException(message: message ?? 'An unexpected error occurred');
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Server error occurred!';

    if (data is Map) {
      // Try common error message keys
      if (data['message'] != null) return data['message'].toString();
      if (data['error'] != null) return data['error'].toString();
      if (data['errors'] != null) {
        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          return (data['errors'] as List).first.toString();
        }
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            return errors.values.first.toString();
          }
        }
      }
    }

    return 'Server error occurred';
  }

  /// Legacy method for backward compatibility
  ServerException toServerException() {
    final exception = toAppException();
    if (exception is ServerException) return exception;
    if (exception is UnauthorizedException) {
      return ServerException(message: exception.message, statusCode: exception.statusCode);
    }
    return ServerException(message: exception.toString());
  }
}
