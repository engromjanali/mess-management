import 'package:dio/dio.dart';

/// Exception classes
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  /// Per-field messages from a DRF validation error (`{"title": ["..."]}`),
  /// so a form can show each one under its own field.
  final Map<String, String> fieldErrors;

  ServerException({required this.message, this.statusCode, this.fieldErrors = const {}});
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
        return ServerException(message: _extractErrorMessage(response?.data), statusCode: statusCode, fieldErrors: _extractFieldErrors(response?.data));
      case DioExceptionType.cancel:
        return ServerException(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return NoInternetException(message: 'No internet connection. Please check your network.');
      default:
        return ServerException(message: message ?? error?.toString() ?? 'An unexpected error occurred');
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
      // Django REST framework errors: {"detail": "..."}, {"non_field_errors": [...]}, {"field": [...]}
      if (data['detail'] != null) return data['detail'].toString();
      for (final value in [data['non_field_errors'], ...data.values]) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.isNotEmpty) return value;
      }
    }

    return 'Server error occurred';
  }

  /// First message of each field in a DRF error body, skipping the general keys.
  Map<String, String> _extractFieldErrors(dynamic data) {
    if (data is! Map) return const {};
    const generalKeys = {'detail', 'message', 'error', 'errors', 'non_field_errors'};
    final result = <String, String>{};
    data.forEach((key, value) {
      if (generalKeys.contains(key)) return;
      if (value is List && value.isNotEmpty && value.first is String) result['$key'] = value.first as String;
      if (value is String && value.isNotEmpty) result['$key'] = value;
    });
    return result;
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
