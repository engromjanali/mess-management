import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/home/data/datasources/local/home_local_data_source_impl.dart';
import 'package:clean_boilerplate/features/home/domain/entities/dashboard_entity.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/member_stats_table.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Dashboard uses live selected-season member totals and refreshes without explicit IDs', () async {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    addTearDown(dio.close);
    var role = 'manager';
    var isMember = true;
    var deposit = 2200;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.path == '/api/v1/user/notices') {
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'data': []}));
        return;
      }
      expect(options.path, '/api/v1/user/mess');
      expect(options.queryParameters, isEmpty);
      expect(options.extra['sensitive'], isTrue);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'season': {'name': 'Current season'},
        'my_stats': {'meal': 2.5, 'deposit': deposit, 'remaining': deposit - 250},
        'my_role': role,
        'is_member': isMember,
        'stats': {'meal_rate': 100, 'total_deposit': deposit, 'total_meals': 2.5, 'total_cost': 250, 'fund_balance': 800},
        if (role != 'member') 'member_stats': [{'id': 8, 'name': 'Actual member', 'deposit': deposit, 'meal': 2.5}],
      }));
    }));
    final source = HomeLocalDataSourceImpl(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    final initial = (await source.getDashboard()).toEntity();
    expect(initial.isManager, isTrue);
    expect(initial.myTotalMeal, 2.5);
    expect(initial.myDeposit, 2200);
    expect(initial.myRemaining, 1950);
    expect(initial.members.single.name, 'Actual member');
    expect(initial.members.single.remaining(initial.mealRate), 1950);
    deposit = 2500;
    expect((await source.getDashboard()).members.single.deposit, 2500);
    role = 'member';
    isMember = false;
    final member = await source.getDashboard();
    expect(member.isManager, isFalse);
    expect(member.isMember, isFalse);
    expect(member.members, isEmpty);
  });

  test('Notice service failure does not hide live dashboard totals', () async {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      if (request.path == '/api/v1/user/notices') {
        handler.reject(DioException(requestOptions: request, response: Response<dynamic>(requestOptions: request, statusCode: 503), type: DioExceptionType.badResponse), true);
      } else {
        handler.resolve(Response(requestOptions: request, statusCode: 200, data: {
          'season': {'name': 'Current'},
          'stats': {'meal_rate': 50, 'total_deposit': 900, 'total_meals': 4, 'total_cost': 200, 'fund_balance': 0},
          'my_stats': {'meal': 4, 'deposit': 900, 'remaining': 700},
        }));
      }
    }));
    final source = HomeLocalDataSourceImpl(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    final dashboard = await source.getDashboard();
    expect(dashboard.myRemaining, 700);
    expect(dashboard.totalDeposit, 900);
    expect(dashboard.pinnedNotice, isNull);
  });

  testWidgets('Member totals fit small screens, translations and large text', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final members = List.generate(6, (index) => MemberStatEntity(id: '$index', name: 'A long member name $index', deposit: 12345678.99, meal: 1234.5));
    for (final width in [320.0, 390.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1000);
      for (final language in ['en', 'bn', 'ar']) {
        for (final scale in [1.0, 2.0]) {
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SingleChildScrollView(child: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: MemberStatsTable(members: members, mealRate: 20000)))),
          ));
          await tester.pumpAndSettle();
          expect(find.text('A long member name 4'), findsNothing);
          final local = AppLocalizations.of(tester.element(find.byType(MemberStatsTable)));
          await tester.tap(find.text(local.uiShowAllMembers));
          await tester.pumpAndSettle();
          expect(find.text('A long member name 5'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: '$width $language $scale');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });

  testWidgets('Member table displays an empty state without sample members', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: MemberStatsTable(members: [], mealRate: 0)),
    ));
    expect(find.text('No members yet'), findsOneWidget);
    expect(find.text('Show all members'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
