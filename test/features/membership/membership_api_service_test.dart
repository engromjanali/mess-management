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
    expect(request!.data, {'name': 'Green House', 'address': 'Mirpur', 'email': 'house@example.com', 'phone': '01711111111'});
    dio.close();
  });
}
