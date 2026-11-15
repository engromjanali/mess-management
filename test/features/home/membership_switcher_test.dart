import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/membership/data/membership_api_service.dart';
import 'package:mess_pilot/features/membership/domain/entities/membership_status_entity.dart';
import 'package:mess_pilot/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _TestAuthBloc() : super(const AuthState.initial());

  @override
  Future<void> refreshProfile() async {}
}

class _TestThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  _TestThemeBloc() : super(const ThemeState.light());
}

class _TestLocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> implements LocalizationBloc {
  _TestLocalizationBloc(Locale locale) : super(LocalizationState.initial(locale));
}

Map<String, dynamic> _membership({
  required int membershipId,
  required int seasonId,
  required int messId,
  required String messName,
  required String seasonName,
  required String role,
  required String status,
  required String seasonStartDate,
  required bool isCurrent,
  required bool canSwitch,
}) => {
  'membership_id': membershipId,
  'season_id': seasonId,
  'mess_id': messId,
  'mess_name': messName,
  'season_name': seasonName,
  'role': role,
  'status': status,
  'season_start_date': seasonStartDate,
  'is_current': isCurrent,
  'can_switch': canSwitch,
};

Map<String, dynamic> _status(String currentSeason) {
  final current = currentSeason == 'Spring 2026'
      ? _membership(membershipId: 1, seasonId: 1, messId: 10, messName: 'Sunrise Mess', seasonName: 'Spring 2026', role: 'member', status: 'active', seasonStartDate: '2026-01-01', isCurrent: true, canSwitch: false)
      : _membership(membershipId: 2, seasonId: 2, messId: 10, messName: 'Sunrise Mess', seasonName: 'Winter 2025', role: 'manager', status: 'active', seasonStartDate: '2025-06-01', isCurrent: true, canSwitch: false);
  return {
    'current': current,
    'memberships': [
      _membership(membershipId: 1, seasonId: 1, messId: 10, messName: 'Sunrise Mess', seasonName: 'Spring 2026', role: 'member', status: 'active', seasonStartDate: '2026-01-01', isCurrent: currentSeason == 'Spring 2026', canSwitch: currentSeason != 'Spring 2026'),
      _membership(membershipId: 2, seasonId: 2, messId: 10, messName: 'Sunrise Mess', seasonName: 'Winter 2025', role: 'manager', status: 'active', seasonStartDate: '2025-06-01', isCurrent: currentSeason == 'Winter 2025', canSwitch: currentSeason != 'Winter 2025'),
      _membership(membershipId: 3, seasonId: 3, messId: 10, messName: 'Sunrise Mess', seasonName: 'Autumn 2024', role: 'member', status: 'left', seasonStartDate: '2024-01-01', isCurrent: false, canSwitch: false),
      _membership(membershipId: 4, seasonId: 4, messId: 99, messName: 'Other Mess', seasonName: 'Other Mess Season', role: 'member', status: 'active', seasonStartDate: '2025-01-01', isCurrent: false, canSwitch: true),
    ],
    'history': [],
    'pending_requests': [],
    'join_requests': [],
    'invites': [],
  };
}

Widget _app({required GoRouter router, required MembershipCubit membershipCubit, required Locale locale}) => MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>(create: (_) => _TestAuthBloc()),
    BlocProvider<ThemeBloc>(create: (_) => _TestThemeBloc()),
    BlocProvider<LocalizationBloc>(create: (_) => _TestLocalizationBloc(locale)),
    BlocProvider<MembershipCubit>.value(value: membershipCubit),
  ],
  child: MaterialApp.router(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.2)), child: child!),
    routerConfig: router,
  ),
);

void main() {
  testWidgets('Membership menu lists only the current mess and never overflows', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    for (final width in [900.0, 1440.0]) {
      for (final locale in [const Locale('en'), const Locale('bn'), const Locale('ar')]) {
        tester.view.physicalSize = Size(width, 900);
        final dio = Dio();
        dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
          if (options.method == 'GET' && options.path == AppConstants.membershipStatusEndpoint) {
            return handler.resolve(Response(requestOptions: options, data: _status('Spring 2026')));
          }
          handler.reject(DioException(requestOptions: options));
        }));
        final apiClient = ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance());
        final membershipCubit = MembershipCubit(MembershipApiService(apiClient));
        addTearDown(membershipCubit.close);
        addTearDown(dio.close);

        final router = GoRouter(
          initialLocation: AppRoutes.home,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => Scaffold(
                body: DashboardTopBar(onProfileTap: () {}, showNotifications: false),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        unawaited(membershipCubit.load());
        await tester.pumpWidget(_app(router: router, membershipCubit: membershipCubit, locale: locale));
        await tester.pumpAndSettle();

        expect(find.text('Sunrise Mess'), findsOneWidget);
        expect(find.text('S'), findsOneWidget);
        await tester.tap(find.byType(PopupMenuButton<MembershipSummaryEntity>));
        await tester.pumpAndSettle();

        expect(find.text('Winter 2025'), findsOneWidget);
        expect(find.text('Autumn 2024'), findsOneWidget);
        expect(find.text('Other Mess Season'), findsNothing);
        expect(find.text('Other Mess'), findsNothing);
        expect(tester.takeException(), isNull, reason: '$width $locale');
      }
    }
  });

  testWidgets('Selecting a membership switches and reloads the current context', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    var currentSeason = 'Spring 2026';
    final switchRequests = <Map<String, dynamic>>[];
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.method == 'GET' && options.path == AppConstants.membershipStatusEndpoint) {
        return handler.resolve(Response(requestOptions: options, data: _status(currentSeason)));
      }
      if (options.method == 'POST' && options.path == AppConstants.switchMembershipEndpoint) {
        switchRequests.add(Map<String, dynamic>.from(options.data as Map));
        currentSeason = 'Winter 2025';
        return handler.resolve(Response(requestOptions: options, data: {}));
      }
      handler.reject(DioException(requestOptions: options));
    }));
    final apiClient = ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance());
    final membershipCubit = MembershipCubit(MembershipApiService(apiClient));
    addTearDown(membershipCubit.close);
    addTearDown(dio.close);

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => Scaffold(
            body: DashboardTopBar(onProfileTap: () {}, showNotifications: false),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    unawaited(membershipCubit.load());
    await tester.pumpWidget(_app(router: router, membershipCubit: membershipCubit, locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Spring 2026'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<MembershipSummaryEntity>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Winter 2025'));
    await tester.pumpAndSettle();

    expect(switchRequests, [
      {'membership_id': 2, 'mess_id': 10, 'season_id': 2},
    ]);
    expect(find.text('Winter 2025'), findsOneWidget);
    expect(find.text('Spring 2026'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Membership chip limits mess and season names', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final status = _status('Spring 2026');
    final current = Map<String, dynamic>.from(status['current'] as Map<String, dynamic>)
      ..['mess_name'] = 'Sunrise Mess With A Very Long Name'
      ..['season_name'] = 'Spring 2026 Season Name';
    status['current'] = current;
    (status['memberships'] as List<dynamic>)[0] = current;

    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.method == 'GET' && options.path == AppConstants.membershipStatusEndpoint) {
        return handler.resolve(Response(requestOptions: options, data: status));
      }
      handler.reject(DioException(requestOptions: options));
    }));
    final apiClient = ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance());
    final membershipCubit = MembershipCubit(MembershipApiService(apiClient));
    addTearDown(membershipCubit.close);
    addTearDown(dio.close);

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => Scaffold(
            body: DashboardTopBar(onProfileTap: () {}, showNotifications: false),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    unawaited(membershipCubit.load());
    await tester.pumpWidget(_app(router: router, membershipCubit: membershipCubit, locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Sunrise Mess W…'), findsOneWidget);
    expect(find.text('Spring 2026 Season…'), findsOneWidget);
    expect(find.text('Sunrise Mess With A Very Long Name'), findsNothing);
    expect(find.text('Spring 2026 Season Name'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
