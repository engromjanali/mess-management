import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
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
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    // Add interceptors
    dio.interceptors.add(PrettyDioLogger(requestHeader: false, requestBody: false, responseBody: false));

    return dio;
  }
}
