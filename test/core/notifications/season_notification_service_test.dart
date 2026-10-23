import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/notifications/season_notification_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Permission extends Fake implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus => AuthorizationStatus.authorized;
}

class _Messaging extends Fake implements FirebaseMessaging {
  final removedTopics = <String>[];
  int deletedTokens = 0;

  @override
  Future<NotificationSettings> requestPermission({bool alert = true, bool announcement = false, bool badge = true, bool carPlay = false, bool criticalAlert = false, bool provisional = false, bool sound = true, bool providesAppNotificationSettings = false}) async => _Permission();

  @override
  Future<String?> getToken({String? vapidKey, String? serviceWorkerScriptPath}) async => 'device-token';

  @override
  Future<void> setForegroundNotificationPresentationOptions({bool alert = false, bool badge = false, bool sound = false}) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async { removedTopics.add(topic); }

  @override
  Future<void> deleteToken() async { deletedTokens++; }
}

class _Client extends Fake implements ApiClient {
  int posts = 0;
  final requests = <RequestOptions>[];
  late Map<String, dynamic> Function(int) response;

  @override
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    requests.add(RequestOptions(path: path, data: data, extra: options?.extra));
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 200, data: response(++posts) as T);
  }

  @override
  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    requests.add(RequestOptions(path: path, data: data, extra: options?.extra));
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 204);
  }
}

void main() {
  testWidgets('Failed registration retries and keeps confirmed topics after malformed response', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = _Client();
    final messaging = _Messaging();
    final service = SeasonNotificationService(client, messaging: messaging);
    addTearDown(() { service.dispose(); debugDefaultTargetPlatformOverride = null; });
    client.response = (count) {
      if (count == 1) throw StateError('Network unavailable');
      return count == 2 ? {'topics': ['topic_seasonId_42', 'topic_messId_7']} : {'topics': ['topic_seasonId_99', 123]};
    };
    service.setAuthenticated(true);
    await tester.pump();
    expect(client.posts, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(client.posts, 2);
    await service.sync();
    expect(client.posts, 3);
    await service.signOut();
    expect(messaging.removedTopics, ['topic_seasonId_42', 'topic_messId_7']);
    expect(messaging.deletedTokens, 1);
    expect(client.requests.every((request) => request.path == AppConstants.pushDeviceEndpoint && request.extra['sensitive'] == true && request.data['token'] == 'device-token'), isTrue);
    await tester.pump(const Duration(minutes: 2));
    expect(client.posts, 3);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Retry backs off and stops in background and after disposal', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = _Client();
    final service = SeasonNotificationService(client, messaging: _Messaging());
    addTearDown(() { service.dispose(); debugDefaultTargetPlatformOverride = null; });
    client.response = (_) => throw StateError('Network unavailable');
    service.setAuthenticated(true);
    await tester.pump();
    expect(client.posts, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(client.posts, 2);
    await tester.pump(const Duration(seconds: 9));
    expect(client.posts, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(client.posts, 3);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 2));
    expect(client.posts, 3);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(client.posts, 4);
    service.dispose();
    await tester.pump(const Duration(minutes: 2));
    expect(client.posts, 4);
    debugDefaultTargetPlatformOverride = null;
  });
}
