import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/core/notifications/notification_unread_service.dart';
import 'package:mess_pilot/core/widgets/notification_icon_button.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Unread state clears on account change and ignores stale responses', () async {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    final requests = <RequestInterceptorHandler>[];
    final options = <RequestOptions>[];
    final arrivals = List.generate(3, (_) => Completer<void>());
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      options.add(request);
      requests.add(handler);
      arrivals[requests.length - 1].complete();
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    final service = NotificationUnreadService();
    addTearDown(() async { service.setUser(null); service.dispose(); await getIt.reset(); });
    service.setUser('first');
    await arrivals[0].future;
    service.setUser('second');
    await arrivals[1].future;
    requests[0].resolve(Response(requestOptions: options[0], data: {'has_unread': true}));
    requests[1].resolve(Response(requestOptions: options[1], data: {'has_unread': false}));
    await Future<void>.delayed(Duration.zero);
    expect(service.value, isFalse);
    final refresh = service.refresh();
    await arrivals[2].future;
    requests[2].resolve(Response(requestOptions: options[2], data: {'has_unread': true}));
    await refresh;
    expect(service.value, isTrue);
    service.setUser(null);
    expect(service.value, isFalse);
  });

  testWidgets('Bell shows only a small red dot for unread notifications', (tester) async {
    final service = NotificationUnreadService.instance;
    addTearDown(() => service.value = false);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NotificationIconButton()),
    ));
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    service.value = true;
    await tester.pump();
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
    expect(badge.backgroundColor, Colors.red);
    expect(badge.label, isNull);
    expect(tester.takeException(), isNull);
    service.value = false;
    await tester.pump();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
  });
}
