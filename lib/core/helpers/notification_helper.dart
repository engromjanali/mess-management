import 'dart:async';

import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/core/helpers/auth_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final instance = NotificationHelper();
  final _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _pendingRoute;
  bool _listening = false;
  bool _initialized = false;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  RemoteMessage _message(String? payload) => RemoteMessage(data: {'type': 'notice', 'notice_id': payload});

  static String? noticeNotificationRoute(Map<String, dynamic> data) {
    final id = data['notice_id'];
    if (data['type'] != 'notice' || id is! String || !RegExp(r'^[1-9][0-9]*$').hasMatch(id)) return null;
    return AppRoutes.getNoticeDetailsRoute(id);
  }

  Future<void> initialize() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) return;
    try {
      final destination = await _initializeLocal();
      if (destination != null) initialDestination = destination;
    } catch (_) {
      debugPrint('Foreground notification initialization unavailable.');
    }
    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      // FCM handles background display; this resolves a terminated-app tap.
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) initialDestination = noticeNotificationRoute(message.data) ?? initialDestination;
    } catch (_) {
      debugPrint('Initial notification unavailable.');
    }
  }

  void start() {
    if (_listening || kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) return;
    _listening = true;
    _tapSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
    if (_supported) _foregroundSubscription = FirebaseMessaging.onMessage.listen(show);
    router.routerDelegate.addListener(_openPendingNotification);
  }

  void _onTap(RemoteMessage message) {
    final destination = noticeNotificationRoute(message.data);
    if (destination == null) return;
    _pendingRoute = destination;
    _openPendingNotification();
  }

  void _openPendingNotification() {
    if (!_listening || _pendingRoute == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listening || _pendingRoute == null) return;
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if ([AppRoutes.getSplashRoute(), AppRoutes.maintenance, AppRoutes.updateRequired].contains(path)) return;
      final destination = _pendingRoute!;
      _pendingRoute = null;
      router.go(AuthHelper.isLogin() ? destination : AppRoutes.loginRouteFor(destination));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void dispose() {
    _listening = false;
    _tapSubscription?.cancel();
    _foregroundSubscription?.cancel();
    router.routerDelegate.removeListener(_openPendingNotification);
    _pendingRoute = null;
  }

  Future<String?> _initializeLocal() async {
    if (!_supported) return null;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notice_notification')),
      onDidReceiveNotificationResponse: (response) => _onTap(_message(response.payload)),
    );
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(const AndroidNotificationChannel('notices', 'Notices', importance: Importance.high));
    _initialized = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp == true ? noticeNotificationRoute(_message(launch?.notificationResponse?.payload).data) : null;
  }

  Future<void> show(RemoteMessage message) async {
    if (!_supported || !_initialized || !AuthHelper.isLogin() || noticeNotificationRoute(message.data) == null) return;
    final notification = message.notification;
    if (notification == null) return;
    try {
      final noticeId = message.data['notice_id'] as String;
      await _plugin.show(
        id: noticeId.hashCode & 0x7fffffff,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('notices', 'Notices', icon: 'ic_notice_notification', importance: Importance.high, priority: Priority.high)),
        payload: noticeId,
      );
    } catch (_) {
      debugPrint('Foreground notice notification unavailable.');
    }
  }

  Future<void> clear() async {
    if (_supported && _initialized) await _plugin.cancelAll();
  }
}
