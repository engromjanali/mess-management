import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/network/api_client.dart';

class NotificationUnreadService extends ValueNotifier<bool> {
  NotificationUnreadService() : super(false);

  static final instance = NotificationUnreadService();
  String? _userId;
  CancelToken? _cancelToken;
  Future<void>? _pending;
  bool _refreshAgain = false;

  void setUser(String? userId) {
    if (_userId == userId) return;
    _cancelToken?.cancel();
    _userId = userId;
    _pending = null;
    _refreshAgain = false;
    value = false;
    if (userId != null) refresh();
  }

  Future<void> refresh() {
    if (_userId == null) return Future<void>.value();
    if (_pending != null) {
      _refreshAgain = true;
      return _pending!;
    }
    final token = CancelToken();
    _cancelToken = token;
    late final Future<void> pending;
    pending = _load(token).whenComplete(() {
      if (_pending == pending) _pending = null;
    });
    _pending = pending;
    return pending;
  }

  Future<void> _load(CancelToken token) async {
    do {
      _refreshAgain = false;
      try {
        final response = await getIt<ApiClient>().get<Map<String, dynamic>>('/api/v1/user/notifications', queryParameters: {'unread_only': 'true'}, options: Options(extra: {'sensitive': true}), cancelToken: token);
        if (token.isCancelled) return;
        value = response.data?['has_unread'] == true;
      } catch (_) {
        // Retain the last confirmed state while offline.
      }
    } while (!token.isCancelled && _refreshAgain);
  }
}
