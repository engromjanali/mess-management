import 'dart:async';
import 'dart:convert';

import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clean_boilerplate/core/errors/exceptions.dart';

@singleton
class ApiClient {
  final Dio _dio;
  final SharedPreferences _sharedPreferences;

  String? _token;
  String? _refreshToken;
  String? _guestUserId;
  String? _languageCode;
  Future<void>? _refreshing;
  int _authGeneration = 0;

  /// Called once when an authenticated request gets a 401, after the tokens are cleared.
  VoidCallback? onUnauthorized;

  ApiClient({required Dio dio, required SharedPreferences sharedPreferences}) : _dio = dio, _sharedPreferences = sharedPreferences {
    _initializeHeaders();
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      request.extra.putIfAbsent('authGeneration', () => _authGeneration);
      handler.next(request);
    }, onError: (error, handler) async {
      final request = error.requestOptions;
      final authorization = request.headers['Authorization'];
      final excluded = [AppConstants.loginEndpoint, AppConstants.registerEndpoint, AppConstants.refreshTokenEndpoint, AppConstants.logoutEndpoint];
      if (request.extra['authGeneration'] != _authGeneration || error.response?.statusCode != 401 || request.extra['authRetried'] == true || excluded.contains(request.path) || authorization == null || _token == null || _refreshToken == null) {
        handler.next(error);
        return;
      }
      try {
        if (authorization == 'Bearer $_token') {
          await (_refreshing ??= _refreshTokens().whenComplete(() => _refreshing = null));
        }
        if (_token == null) { handler.next(error); return; }
        final data = request.data;
        final response = await _dio.fetch<dynamic>(request.copyWith(
          headers: {...request.headers, 'Authorization': 'Bearer $_token'},
          extra: {...request.extra, 'authRetried': true},
          data: data is FormData ? data.clone() : data,
        ));
        handler.resolve(response);
      } on DioException catch (failure) {
        handler.reject(failure);
      } catch (_) {
        handler.next(error);
      }
    }));
  }

  Future<void> _refreshTokens() async {
    final session = _authGeneration;
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.refreshTokenEndpoint,
      data: {'refresh_token': _refreshToken},
      options: Options(headers: {'Authorization': null}, extra: {'sensitive': true}),
    );
    if (_authGeneration != session) throw DioException(requestOptions: response.requestOptions, type: DioExceptionType.cancel);
    final access = response.data?['access_token'];
    final refresh = response.data?['refresh_token'];
    if (access is! String || access.isEmpty || refresh is! String || refresh.isEmpty) {
      throw DioException(requestOptions: response.requestOptions, response: Response<dynamic>(requestOptions: response.requestOptions, statusCode: 401), type: DioExceptionType.badResponse);
    }
    await _persistToken(access);
    await updateRefreshToken(refresh);
  }

  /// Initialize headers from SharedPreferences
  void _initializeHeaders() {
    _token = _sharedPreferences.getString(AppConstants.tokenKey);
    _refreshToken = _sharedPreferences.getString(AppConstants.refreshTokenKey);
    _guestUserId = _sharedPreferences.getString(AppConstants.guestUserIdKey);
    _languageCode = _sharedPreferences.getString(AppConstants.languageCodeKey) ?? _sharedPreferences.getString('locale_code') ?? 'en';

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
    _authGeneration++;
    await _persistToken(token);
  }

  Future<void> _persistToken(String? token) async {
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
        print('=====> Query Parameters: ${options?.extra?['sensitive'] == true ? '[REDACTED]' : _formatLogValue(queryParameters)}');
      }

      final response = await _dio.get<T>(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);

      _logResponse(response);

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message ?? e.error}');
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
        print('=====> POST: $path');
        print('=====> Body: ${options?.extra?['sensitive'] == true ? '[REDACTED]' : _formatLogValue(data)}');
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

      _logResponse(response);

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message ?? e.error}');
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
        print('=====> Body: ${_formatLogValue(data)}');
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

      _logResponse(response);

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message ?? e.error}');
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
        print('=====> Body: ${options?.extra?['sensitive'] == true ? '[REDACTED]' : _formatLogValue(data)}');
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

      _logResponse(response);

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message ?? e.error}');
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

      _logResponse(response);

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message ?? e.error}');
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
        print('=====> Data: ${_formatLogValue(data)}');
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

      _logResponse(response);

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=====> Error: ${e.type} - ${e.message ?? e.error}');
      }
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    // `_token` guard: parallel 401s trigger the logout/redirect only once.
    if (error.response?.statusCode == 401 && _token != null && error.requestOptions.extra['authGeneration'] == _authGeneration && ![AppConstants.loginEndpoint, AppConstants.registerEndpoint].contains(error.requestOptions.path)) {
      unawaited(clearTokens());
      onUnauthorized?.call();
    }
    return error.toAppException();
  }

  void _logResponse(Response<dynamic> response) {
    if (!kDebugMode) return;
    debugPrint('=====> Response [${response.statusCode}] ${response.requestOptions.method}: ${response.requestOptions.uri.replace(query: '')}');
    debugPrint('=====> Data: ${response.requestOptions.extra['sensitive'] == true ? '[REDACTED]' : _formatLogValue(response.data)}');
  }

  String _formatLogValue(dynamic value) {
    final sanitized = _sanitizeLogValue(value);
    if (sanitized is Map || sanitized is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(sanitized);
      } catch (_) {
        return sanitized.toString();
      }
    }
    return sanitized?.toString() ?? 'null';
  }

  dynamic _sanitizeLogValue(dynamic value, [String? key]) {
    final normalizedKey = key?.toLowerCase().replaceAll('-', '_');
    if (normalizedKey != null && (normalizedKey.contains('password') || normalizedKey.contains('token') || normalizedKey.contains('secret') || normalizedKey.contains('authorization') || normalizedKey.contains('api_key') || normalizedKey.contains('otp') || normalizedKey.contains('email') || normalizedKey.contains('phone') || normalizedKey.contains('address') || normalizedKey.contains('name') || normalizedKey == 'lat' || normalizedKey == 'long' || normalizedKey == 'latitude' || normalizedKey == 'longitude' || normalizedKey == 'photo' || normalizedKey == 'query' || normalizedKey == 'q' || normalizedKey == 'search')) return '[REDACTED]';
    if (value is Map) return value.map((key, value) => MapEntry(key.toString(), _sanitizeLogValue(value, key.toString())));
    if (value is List) return value.map((item) => _sanitizeLogValue(item)).toList();
    if (value is FormData) return '[FormData]';
    return value;
  }
}
