import 'dart:async';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Dio dio;
  late ApiClient client;

  setUp(() async {
    SharedPreferences.setMockInitialValues({AppConstants.tokenKey: 'old', AppConstants.refreshTokenKey: 'refresh'});
    dio = Dio();
    client = ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance());
  });
  tearDown(() => dio.close());

  void reject(RequestOptions request, RequestInterceptorHandler handler, int status) {
    handler.reject(DioException(requestOptions: request, response: Response<dynamic>(requestOptions: request, statusCode: status), type: DioExceptionType.badResponse), true);
  }

  test('Concurrent expired requests share one refresh and retry with new credentials', () async {
    var refreshes = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) async {
      if (request.path == AppConstants.refreshTokenEndpoint) {
        refreshes++;
        expect(request.headers['Authorization'], isNull);
        expect(request.data, {'refresh_token': 'refresh'});
        await Future<void>.delayed(const Duration(milliseconds: 10));
        handler.resolve(Response(requestOptions: request, statusCode: 200, data: {'access_token': 'new', 'refresh_token': 'next'}));
      } else if (request.headers['Authorization'] == 'Bearer old') {
        reject(request, handler, 401);
      } else {
        expect(request.headers['Authorization'], 'Bearer new');
        handler.resolve(Response(requestOptions: request, statusCode: 200, data: {'ok': true}));
      }
    }));
    final responses = await Future.wait([client.get('/first'), client.get('/second')]);
    expect(responses.every((response) => response.statusCode == 200), isTrue);
    expect(refreshes, 1);
    expect(client.refreshToken, 'next');
  });

  test('Invalid refresh clears credentials and notifies once', () async {
    var notifications = 0;
    client.onUnauthorized = () => notifications++;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) => reject(request, handler, 401)));
    await expectLater(client.get('/private'), throwsA(isA<UnauthorizedException>()));
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 1);
    expect(client.refreshToken, isNull);
    expect(dio.options.headers['Authorization'], isNull);
  });

  test('Temporary refresh failure preserves the session', () async {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) => reject(request, handler, request.path == AppConstants.refreshTokenEndpoint ? 503 : 401)));
    await expectLater(client.get('/private'), throwsA(isA<ServerException>()));
    expect(client.refreshToken, 'refresh');
    expect(dio.options.headers['Authorization'], 'Bearer old');
  });

  test('Logout during refresh cannot restore old credentials or replay the request', () async {
    final started = Completer<void>();
    final finish = Completer<void>();
    var retried = false;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) async {
      if (request.path == AppConstants.refreshTokenEndpoint) {
        started.complete();
        await finish.future;
        handler.resolve(Response(requestOptions: request, statusCode: 200, data: {'access_token': 'new', 'refresh_token': 'next'}));
      } else {
        if (request.extra['authRetried'] == true) retried = true;
        reject(request, handler, 401);
      }
    }));
    final pending = expectLater(client.get('/private'), throwsA(isA<ServerException>()));
    await started.future;
    await client.clearTokens();
    finish.complete();
    await pending;
    expect(dio.options.headers['Authorization'], isNull);
    expect(client.refreshToken, isNull);
    expect(retried, isFalse);
  });

  test('A retry that still returns 401 does not loop', () async {
    var refreshes = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      if (request.path == AppConstants.refreshTokenEndpoint) {
        refreshes++;
        handler.resolve(Response(requestOptions: request, statusCode: 200, data: {'access_token': 'new', 'refresh_token': 'next'}));
      } else {
        reject(request, handler, 401);
      }
    }));
    await expectLater(client.get('/private'), throwsA(isA<UnauthorizedException>()));
    expect(refreshes, 1);
  });
}
