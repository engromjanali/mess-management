import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/membership/presentation/screens/manage_membership_screen.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _AuthBloc() : super(const AuthState.initial());

  @override
  Future<void> refreshProfile() async {}
}

void main() {
  testWidgets('Shows every mess first and loads only the tapped mess seasons', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    var requests = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests++;
      expect(options.path, '/api/v1/user/membership/status');
      expect(options.queryParameters, isEmpty);
      handler.resolve(Response(requestOptions: options, data: {
        'current': null,
        'memberships': [
          {'membership_id': 1, 'season_id': 11, 'mess_id': 1, 'mess_name': 'Green House', 'season_name': 'Summer', 'role': 'member', 'status': 'active', 'season_start_date': '2026-06-01', 'is_current': true, 'can_switch': false},
          {'membership_id': 2, 'season_id': 10, 'mess_id': 1, 'mess_name': 'Green House', 'season_name': 'Spring', 'role': 'member', 'status': 'left', 'season_start_date': '2026-03-01', 'can_switch': false},
          {'membership_id': 3, 'season_id': 20, 'mess_id': 2, 'mess_name': 'Blue House', 'season_name': 'Current season', 'role': 'member', 'status': 'active', 'season_start_date': '2026-05-01', 'can_switch': true},
        ],
        'history': [],
        'pending_requests': [],
        'join_requests': [],
        'invites': [],
      }));
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() => getIt.reset());

    for (final language in ['en', 'bn', 'ar']) {
      await tester.pumpWidget(BlocProvider<AuthBloc>(
        key: ValueKey(language),
        create: (_) => _AuthBloc(),
        child: MaterialApp(
          theme: AppTheme.light,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
          home: const ManageMembershipScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Green House'), findsOneWidget);
      expect(find.text('Blue House'), findsOneWidget);
      expect(find.text('Summer'), findsNothing);
      expect(find.text('Spring'), findsNothing);
      expect(tester.takeException(), isNull, reason: '$language mess list');

      await tester.tap(find.byKey(const ValueKey('membership-mess-1')));
      await tester.pumpAndSettle();
      expect(find.text('Summer'), findsOneWidget);
      expect(find.text('Spring'), findsOneWidget);
      expect(find.text('Blue House'), findsNothing);
      expect(tester.takeException(), isNull, reason: language);

      await tester.tap(find.byKey(const ValueKey('membership-all-messes-back')));
      await tester.pumpAndSettle();
      expect(find.text('Green House'), findsOneWidget);
      expect(find.text('Blue House'), findsOneWidget);
    }
    expect(requests, 3);
  });
}
