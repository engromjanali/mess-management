import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class NetworkModule {
  @preResolve
  @lazySingleton
  Future<SharedPreferences> get sharedPreferences async => await SharedPreferences.getInstance();

  @lazySingleton
  Dio get dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
        headers: {'Accept': 'application/json'},
      ),
    );
    if (kIsWeb) (dio.httpClientAdapter as dynamic).enableCORSWarning = false;

    return dio;
  }
}
