import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/membership/data/membership_api_service.dart';
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

  test('Leader-only season access keeps membership nullable and switches by season', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final dio = Dio();
    RequestOptions? switchRequest;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.path == '/api/v1/user/membership/status') {
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
          'current': {'membership_id': null, 'mess_id': 3, 'mess_name': 'Green House', 'season_id': 7, 'season_name': 'Old season', 'role': 'manager', 'is_manager': true, 'is_member': false, 'is_acting_manager': false, 'is_current': true, 'can_switch': true},
          'memberships': [{'membership_id': null, 'mess_id': 3, 'mess_name': 'Green House', 'season_id': 7, 'season_name': 'Old season', 'role': 'manager', 'is_manager': true, 'is_member': false, 'is_acting_manager': false, 'is_current': true, 'can_switch': true}],
        }));
        return;
      }
      switchRequest = options;
      handler.resolve(Response(requestOptions: options, statusCode: 200));
    }));
    final service = MembershipApiService(ApiClient(dio: dio, sharedPreferences: preferences));
    final status = await service.getStatus();
    final current = status.current!;
    expect((current.membershipId, current.seasonId), (null, 7));
    expect((current.isManager, current.isMember, current.isActingManager), (true, false, false));

    await service.switchMembership(current);

    expect(switchRequest!.data, {'membership_id': null, 'mess_id': 3, 'season_id': 7});
    dio.close();
  });
}
