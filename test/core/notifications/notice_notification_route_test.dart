import 'package:clean_boilerplate/core/helpers/notification_helper.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Notice notification opens the matching details route', () {
    expect(NotificationHelper.noticeNotificationRoute({'type': 'notice', 'notice_id': '123456', 'season_id': '42'}), '/notices/123456');
  });

  test('Notification destination survives startup and login', () {
    final destination = NotificationHelper.noticeNotificationRoute({'type': 'notice', 'notice_id': '42'})!;
    expect(AppRoutes.startupRoute(destination), '/notices/42');
    final login = Uri.parse(AppRoutes.loginRouteFor(destination));
    expect(login.path, AppRoutes.getLoginRoute());
    expect(login.queryParameters['redirect'], '/notices/42');
  });

  test('Unrelated and malformed notifications cannot navigate', () {
    for (final data in <Map<String, dynamic>>[
      {},
      {'type': 'other', 'notice_id': '42'},
      {'type': 'notice'},
      {'type': 'notice', 'notice_id': 42},
      {'type': 'notice', 'notice_id': '0'},
      {'type': 'notice', 'notice_id': '-1'},
      {'type': 'notice', 'notice_id': '../profile'},
      {'type': 'notice', 'notice_id': '42?redirect=/profile'},
    ]) {
      expect(NotificationHelper.noticeNotificationRoute(data), isNull);
    }
  });
}
