import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/methods/printer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clean_boilerplate/core/errors/exceptions.dart';

/// Centralized API client for making HTTP requests
///
/// Features:
/// - Automatic token management
/// - Centralized error handling
/// - Request/response logging
/// - Support for file uploads
@singleton
class ApiClient {
  final Dio _dio;
  final SharedPreferences _sharedPreferences;

  String? _token;
  String? _refreshToken;
  String? _guestUserId;
  String? _languageCode;

  ApiClient({required Dio dio, required SharedPreferences sharedPreferences}) : _dio = dio, _sharedPreferences = sharedPreferences {
    _initializeHeaders();
  }

  /// Initialize headers from SharedPreferences
  void _initializeHeaders() {
    _token = _sharedPreferences.getString(AppConstants.tokenKey);
    _refreshToken = _sharedPreferences.getString(AppConstants.refreshTokenKey);
    _guestUserId = _sharedPreferences.getString(AppConstants.guestUserIdKey);
    _languageCode = _sharedPreferences.getString(AppConstants.languageCodeKey) ?? 'en';

    _updateHeaders();
  }

  /// Update Dio headers with current token, locale, and guest ID
  void _updateHeaders() {
    final headers = <String, String>{};

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    if (_guestUserId != null && _guestUserId!.isNotEmpty) {
      headers['X-Guest-User-ID'] = _guestUserId!;
    }

    if (_languageCode != null && _languageCode!.isNotEmpty) {
      headers['X-localization'] = _languageCode!;
      headers['locale'] = _languageCode!;
    }

    _dio.options.headers.addAll(headers);

    if (kDebugMode) {
      print('=====> ApiClient Headers Updated: Token: ${_token != null ? 'Set' : 'Not Set'}, Locale: $_languageCode');
    }
  }

  /// Update authentication token
  Future<void> updateToken(String? token) async {
    _token = token;
    if (token != null && token.isNotEmpty) {
      await _sharedPreferences.setString(AppConstants.tokenKey, token);
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      await _sharedPreferences.remove(AppConstants.tokenKey);
      _dio.options.headers.remove('Authorization');
    }

    if (kDebugMode) {
      print('=====> Token Updated: ${token != null ? 'Set' : 'Removed'}');
    }
  }

  /// Current refresh token, if any.
  String? get refreshToken => _refreshToken;

  /// Persist (or clear) the refresh token used to mint new access tokens.
  Future<void> updateRefreshToken(String? refreshToken) async {
    _refreshToken = refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _sharedPreferences.setString(AppConstants.refreshTokenKey, refreshToken);
    } else {
      await _sharedPreferences.remove(AppConstants.refreshTokenKey);
    }
  }

  /// Clear both the access and refresh tokens (e.g. on logout).
  Future<void> clearTokens() async {
    await updateToken(null);
    await updateRefreshToken(null);
  }

  /// Update guest user ID
  Future<void> updateGuestUserId(String? guestUserId) async {
    _guestUserId = guestUserId;
    if (guestUserId != null && guestUserId.isNotEmpty) {
      await _sharedPreferences.setString(AppConstants.guestUserIdKey, guestUserId);
      _dio.options.headers['X-Guest-User-ID'] = guestUserId;
    } else {
      await _sharedPreferences.remove(AppConstants.guestUserIdKey);
      _dio.options.headers.remove('X-Guest-User-ID');
    }
  }

  /// Update language/locale
  Future<void> updateLocale(String languageCode) async {
    _languageCode = languageCode;
    await _sharedPreferences.setString(AppConstants.languageCodeKey, languageCode);
    _dio.options.headers['X-localization'] = languageCode;
    _dio.options.headers['locale'] = languageCode;
  }

  /// GET request
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onReceiveProgress}) async {
    try {
      if (kDebugMode) {
        print('=====> GET: $path');
        print('=====> Query Parameters: $queryParameters');
      }

      final response = await _dio.get<T>(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);

      if (kDebugMode) {
        print('=====> Response [${response.statusCode}]: $path');
      }

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message}');
      }
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (kDebugMode) {
        printer('=====> POST: $path');
        printer('=====> Body: $data');
      }

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (kDebugMode) {
        print('=====> Response [${response.statusCode}]: $path');
      }

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message}');
      }
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (kDebugMode) {
        print('=====> PUT: $path');
        print('=====> Body: $data');
      }

      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (kDebugMode) {
        print('=====> Response [${response.statusCode}]: $path');
      }

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message}');
      }
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (kDebugMode) {
        print('=====> PATCH: $path');
        print('=====> Body: $data');
      }

      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (kDebugMode) {
        print('=====> Response [${response.statusCode}]: $path');
      }

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message}');
      }
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    try {
      if (kDebugMode) {
        print('=====> DELETE: $path');
      }

      final response = await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);

      if (kDebugMode) {
        print('=====> Response [${response.statusCode}]: $path');
      }

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message}');
      }
      throw _handleError(e);
    }
  }

  /// POST multipart request for file uploads
  Future<Response<T>> postMultipart<T>(
    String path, {
    required Map<String, dynamic> data,
    List<MapEntry<String, MultipartFile>>? files,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (kDebugMode) {
        print('=====> POST Multipart: $path');
        print('=====> Data: $data');
        print('=====> Files: ${files?.length ?? 0}');
      }

      final formData = FormData.fromMap(data);

      // Add files if provided
      if (files != null) {
        for (final file in files) {
          formData.files.add(file);
        }
      }

      final response = await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (kDebugMode) {
        print('=====> Response [${response.statusCode}]: $path');
      }

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message}');
      }
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert them to domain exceptions
  Exception _handleError(DioException error) {
    return error.toAppException();
  }
}
