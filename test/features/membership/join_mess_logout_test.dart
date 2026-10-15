import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/login_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/logout_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/register_usecase.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/join_mess_screen.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthRepository implements AuthRepository {
  int logoutCalls = 0;

  @override
  ResultFuture<void> logout() async {
    logoutCalls++;
    return const Success(data: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Logout remains available when joining another mess', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: options.path == AppConstants.membershipStatusEndpoint
            ? <String, dynamic>{
                'current': <String, dynamic>{
                  'membership_id': 5,
                  'season_id': 7,
                  'mess_id': 3,
                  'mess_name': 'Green House',
                  'season_name': 'October 2026',
                  'role': 'member',
                  'is_member': true,
                  'is_current': true,
                },
              }
            : <String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{'current_page': 1, 'last_page': 1, 'total': 0}},
      ));
    }));
    final apiClient = ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance());
    getIt.registerSingleton<ApiClient>(apiClient);
    addTearDown(() async {
      if (getIt.isRegistered<ApiClient>()) await getIt.unregister<ApiClient>();
      dio.close();
    });
    final repository = _AuthRepository();
    final authBloc = AuthBloc(LoginUseCase(repository), RegisterUseCase(repository), LogoutUseCase(repository), GetCurrentUserUseCase(repository));
    const user = UserEntity(id: '1', email: 'member@example.com', name: 'Member', activeMessId: 3);
    final authenticated = authBloc.stream.firstWhere((state) => state == const AuthState.authenticated(user));
    authBloc.add(const AuthEvent.userUpdated(user));
    await authenticated;
    addTearDown(authBloc.close);
    final testRouter = GoRouter(
      initialLocation: AppRoutes.joinMess,
      routes: [
        GoRoute(path: AppRoutes.joinMess, builder: (context, state) => const JoinMessScreen()),
        GoRoute(path: AppRoutes.getLoginRoute(), builder: (context, state) => const Scaffold(body: Center(child: Text('Login screen')))),
      ],
    );
    addTearDown(testRouter.dispose);

    await tester.pumpWidget(BlocProvider.value(
      value: authBloc,
      child: MaterialApp.router(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: testRouter,
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Logout'), findsOneWidget);
    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
    expect(find.text('Login screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
