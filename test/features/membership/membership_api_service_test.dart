import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Mess edits PATCH the existing user mess endpoint with only editable fields', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final dio = Dio();
    RequestOptions? request;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      request = options;
      handler.resolve(Response(requestOptions: options, statusCode: 200));
    }));
    final service = MembershipApiService(ApiClient(dio: dio, sharedPreferences: preferences));
    await service.updateMess(name: 'Green House', address: 'Mirpur', email: 'house@example.com', phone: '01711111111');
    expect(request!.method, 'PATCH');
    expect(request!.path, '/api/v1/user/mess');
    expect(request!.data, {'name': 'Green House', 'address': 'Mirpur', 'email': 'house@example.com', 'phone': '01711111111', 'latitude': null, 'longitude': null});
    await service.updateMess(name: 'Green House', address: 'Mirpur', email: 'house@example.com', phone: '01711111111', latitude: 23.676705700000014, longitude: 90.98840510000002);
    expect((request!.data as Map)['latitude'], '23.6767057');
    expect((request!.data as Map)['longitude'], '90.9884051');
    dio.close();
  });
}
