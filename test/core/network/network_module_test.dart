import 'package:mess_pilot/core/network/network_module.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _NetworkModule extends NetworkModule {}

void main() {
  test('GET omits Content-Type and body requests still use JSON', () async {
    final dio = _NetworkModule().dio;
    addTearDown(dio.close);
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200));
    }));
    await dio.get<void>('/api/v1/user/mess');
    await dio.patch<void>('/api/v1/user/mess', data: {'name': 'House'});
    expect(requests.first.contentType, isNull);
    expect(requests.last.contentType, Headers.jsonContentType);
    expect(requests.first.headers['Accept'], 'application/json');
  });
}
