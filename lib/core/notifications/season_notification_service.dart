import 'package:mess_pilot/core/helpers/notification_helper.dart';
import 'dart:async';

import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class SeasonNotificationService with WidgetsBindingObserver {
  static SeasonNotificationService? instance;
  final ApiClient _apiClient;
  final FirebaseMessaging? _firebaseMessaging;
  Timer? _retryTimer;
  int _retryDelay = 5;
  bool _disposed = false;
  bool _active = true;
  StreamSubscription<String>? _tokenSubscription;
  Future<void> _pending = Future<void>.value();
  bool _authenticated = false;
  Future<void>? _signingOut;
  final Set<String> _topics = {};

  SeasonNotificationService(this._apiClient, {FirebaseMessaging? messaging}) : _firebaseMessaging = messaging;

  FirebaseMessaging get _messaging => _firebaseMessaging ?? FirebaseMessaging.instance;

  bool get _supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  void start() {
    if (!_supported) return;
    WidgetsBinding.instance.addObserver(this);
    // Keep registration tokens compatible with the Firebase Admin token API.
    // ignore: deprecated_member_use
    _tokenSubscription = _messaging.onTokenRefresh.listen((_) => sync());
  }

  void setAuthenticated(bool authenticated) {
    _authenticated = authenticated;
    if (authenticated) {
      _signingOut = null;
      sync();
    }
  }

  Future<void> sync() {
    if (!_supported || !_authenticated || _disposed) return Future<void>.value();
    _retryTimer?.cancel();
    _pending = _pending.then((_) async {
      if (!_authenticated || _disposed) return;
      try {
        final messaging = _messaging;
        final permission = await messaging.requestPermission();
        if (permission.authorizationStatus == AuthorizationStatus.denied) {
          await _removeDevice();
          return;
        }
        if (defaultTargetPlatform == TargetPlatform.iOS && await messaging.getAPNSToken() == null) {
          _scheduleRetry();
          return;
        }
        // ignore: deprecated_member_use
        final token = await messaging.getToken();
        if (!_authenticated || _disposed) return;
        if (token == null) {
          _scheduleRetry();
          return;
        }
        // The server validates membership and owns topic subscriptions, including
        // removal when a member is disabled while this app is closed.
        final response = await _apiClient.post<Map<String, dynamic>>(AppConstants.pushDeviceEndpoint, data: {'token': token}, options: Options(extra: {'sensitive': true}));
        if (!_authenticated || _disposed) return;
        final topics = response.data?['topics'];
        if (topics is! List || topics.any((topic) => topic is! String || !RegExp(r'^topic_(seasonId|messId)_[1-9][0-9]*$').hasMatch(topic))) {
          throw const FormatException('Invalid push topics response');
        }
        // Keep confirmed topics if registration or response validation fails.
        _topics
          ..clear()
          ..addAll(topics.cast<String>());
        _retryDelay = 5;
      } catch (_) {
        debugPrint('Season notification subscription unavailable; retry scheduled.');
        _scheduleRetry();
      }
    });
    return _pending;
  }

  void _scheduleRetry() {
    if (!_authenticated || _disposed || !_active || _retryTimer?.isActive == true) return;
    _retryTimer = Timer(Duration(seconds: _retryDelay), () => sync());
    _retryDelay = _retryDelay < 60 ? (_retryDelay * 2).clamp(5, 60) : 60;
  }

  Future<void> signOut() async {
    if (!_supported) return;
    _authenticated = false;
    try {
      await NotificationHelper.instance.clear();
    } catch (_) {
      debugPrint('Notice notification cleanup unavailable.');
    }
    _retryTimer?.cancel();
    _retryDelay = 5;
    if (_signingOut != null) return _signingOut;
    _pending = _pending.then((_) => _removeDevice());
    _signingOut = _pending;
    await _pending;
  }

  Future<void> _removeDevice() async {
    final messaging = _messaging;
    try {
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) {
        await _apiClient.delete<void>(AppConstants.pushDeviceEndpoint, data: {'token': token}, options: Options(extra: {'sensitive': true}));
      }
    } catch (_) {
      debugPrint('Push device removal unavailable.');
    }
    try {
      for (final topic in _topics) {
        await messaging.unsubscribeFromTopic(topic);
      }
    } catch (_) {
      debugPrint('Local push subscription cleanup unavailable.');
    }
    try {
      // Invalidate the token even if topic removal failed during offline logout.
      // ignore: deprecated_member_use
      await messaging.deleteToken();
      _topics.clear();
    } catch (_) {
      debugPrint('Push token invalidation unavailable.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      sync();
    } else {
      _retryTimer?.cancel();
    }
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tokenSubscription?.cancel();
  }
}
