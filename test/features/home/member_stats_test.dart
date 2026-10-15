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
      expect(options.path, '/api/v1/user/mess');
      expect(options.queryParameters, isEmpty);
      expect(options.extra['sensitive'], isTrue);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'my_role': role,
        'is_member': isMember,
        'stats': {'meal_rate': 100, 'total_deposit': deposit, 'total_meals': 2.5, 'total_cost': 250, 'fund_balance': 800},
        if (role != 'member') 'member_stats': [{'id': 8, 'name': 'Actual member', 'deposit': deposit, 'meal': 2.5}],
      }));
    }));
    final source = HomeLocalDataSourceImpl(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    final initial = (await source.getDashboard()).toEntity();
    expect(initial.isManager, isTrue);
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
          await tester.tap(find.text('Show all members'));
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
