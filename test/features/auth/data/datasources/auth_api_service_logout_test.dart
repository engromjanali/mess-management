import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/auth/data/datasources/remote/auth_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final status in [200, 500, null]) {
    test('Logout notifies the backend and clears both JWTs when response is $status', () async {
      SharedPreferences.setMockInitialValues({AppConstants.tokenKey: 'access-token', AppConstants.refreshTokenKey: 'refresh-token', AppConstants.languageCodeKey: 'bn'});
      final preferences = await SharedPreferences.getInstance();
      final dio = Dio();
      var requests = 0;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests++;
        expect(options.path, AppConstants.logoutEndpoint);
        expect(options.method, 'POST');
        expect(options.headers['Authorization'], 'Bearer access-token');
        if (status == 200) {
          handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'message': 'Logged out successfully.'}));
        } else {
          handler.reject(DioException(requestOptions: options, type: status == null ? DioExceptionType.connectionError : DioExceptionType.badResponse, response: status == null ? null : Response(requestOptions: options, statusCode: status)));
        }
      }));
      final client = ApiClient(dio: dio, sharedPreferences: preferences);
      await AuthApiService(client).logout();
      expect(requests, 1);
      expect(preferences.getString(AppConstants.tokenKey), isNull);
      expect(preferences.getString(AppConstants.refreshTokenKey), isNull);
      expect(client.refreshToken, isNull);
      expect(dio.options.headers.containsKey('Authorization'), isFalse);
      expect(preferences.getString(AppConstants.languageCodeKey), 'bn');
      dio.close();
    });
  }
}
