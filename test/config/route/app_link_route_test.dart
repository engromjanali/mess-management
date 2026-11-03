import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/features/splash/domain/entities/config_entity.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mess_pilot/features/splash/presentation/screens/splash_screeen.dart';
import 'package:mess_pilot/features/splash/presentation/widgets/app_gate.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoadedSplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _LoadedSplashBloc() : super(const SplashState.loaded(ConfigEntity(latestVersion: '1.0.0', minimumVersion: '1.0.0'))) {
    on<SplashEvent>((event, emit) { configRequests++; });
  }

  int configRequests = 0;
}

Widget _routeScreen(BuildContext context, GoRouterState state) => Scaffold(body: Text(state.uri.toString()));

GoRouter _testRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? AppRoutes.getSplashRoute(),
  overridePlatformDefaultLocation: true,
  redirect: appRouteRedirect,
  routes: [
    for (final path in [AppRoutes.home, AppRoutes.getSplashRoute(), AppRoutes.getLoginRoute(), AppRoutes.register, AppRoutes.forgotPassword, AppRoutes.maintenance, AppRoutes.updateRequired, AppRoutes.privacyPolicy, AppRoutes.termsAndConditions, AppRoutes.faq, AppRoutes.support, AppRoutes.noticeDetails])
      GoRoute(path: path, builder: _routeScreen),
  ],
);

Future<void> _sendLink(WidgetTester tester, GoRouter routes, String location) async {
  await routes.routeInformationProvider.didPushRouteInformation(RouteInformation(uri: Uri.parse(location)));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(preferences);
    appStartupComplete = false;
    initialDestination = AppRoutes.home;
    PackageInfo.setMockInitialValues(appName: 'Mess Pilot', packageName: 'com.goraso.messpilot', version: '1.0.0', buildNumber: '1', buildSignature: '');
  });

  tearDown(() async {
    appStartupComplete = false;
    initialDestination = AppRoutes.home;
    await getIt.reset();
  });

  test('Production HTTPS links retain their path, query, and fragment', () {
    expect(AppRoutes.linkLocation('https://messpilot.goraso.com/notices/42?search=a%2Bb&tab=history#details'), '/notices/42?search=a%2Bb&tab=history#details');
    expect(AppRoutes.linkLocation('https://messpilot.goraso.com:443/notices/42'), '/notices/42');
    expect(AppRoutes.linkLocation('https://messpilot.goraso.com'), AppRoutes.home);
    expect(AppRoutes.linkLocation('/notices/42?tab=history'), '/notices/42?tab=history');
    expect(AppRoutes.linkLocation('https://messpilot.goraso.com/#/notices/42?tab=history'), '/notices/42?tab=history');
  });

  test('Untrusted links cannot supply an app destination', () {
    for (final location in [
      'https://example.com/notices/42',
      'https://messpilot.goraso.com.example.com/notices/42',
      'https://messpilot.goraso.com@evil.example/notices/42',
      'https://user:password@messpilot.goraso.com/notices/42',
      'https://messpilot.goraso.com:444/notices/42',
      'http://messpilot.goraso.com/notices/42',
      'messpilot://notices/42',
      '//messpilot.goraso.com/notices/42',
      'https://messpilot.goraso.com/#//evil.example/notices/42',
      'notices/42',
    ]) {
      expect(AppRoutes.linkLocation(location), AppRoutes.home, reason: location);
    }
  });

  test('Startup excludes auth and gate routes and retains a trusted login destination', () {
    for (final path in [AppRoutes.getSplashRoute(), AppRoutes.getLoginRoute(), AppRoutes.register, AppRoutes.forgotPassword, AppRoutes.maintenance, AppRoutes.updateRequired]) {
      expect(AppRoutes.startupRoute('https://messpilot.goraso.com$path'), AppRoutes.home, reason: path);
    }
    final login = Uri.parse(AppRoutes.loginRouteFor('https://messpilot.goraso.com/notices/42?tab=history'));
    expect(login.path, AppRoutes.getLoginRoute());
    expect(login.queryParameters['redirect'], '/notices/42?tab=history');
  });

  test('Refreshing a relative or production login URL preserves its trusted redirect', () {
    for (final prefix in ['', 'https://messpilot.goraso.com']) {
      for (final destination in ['/notices/42?tab=history', 'https://messpilot.goraso.com/notices/42?tab=history']) {
        final location = '$prefix${Uri(path: AppRoutes.getLoginRoute(), queryParameters: {'redirect': destination})}';
        expect(AppRoutes.startupRoute(location), '/notices/42?tab=history');
        final login = Uri.parse(AppRoutes.loginRouteFor(location));
        expect(login.path, AppRoutes.getLoginRoute());
        expect(login.queryParameters['redirect'], '/notices/42?tab=history');
        expect(AppRoutes.startupRoute(login.toString()), '/notices/42?tab=history');
      }
    }
  });

  test('Login refresh rejects untrusted and nested redirect destinations', () {
    for (final destination in [
      'https://evil.example/notices/42',
      '//evil.example/notices/42',
      'javascript:alert(1)',
      'http://messpilot.goraso.com/notices/42',
      'https://user:password@messpilot.goraso.com/notices/42',
      '/login?redirect=/notices/42',
      'https://messpilot.goraso.com/login?redirect=/notices/42',
      AppRoutes.getSplashRoute(),
      AppRoutes.maintenance,
      AppRoutes.updateRequired,
    ]) {
      for (final prefix in ['', 'https://messpilot.goraso.com']) {
        final location = '$prefix${Uri(path: AppRoutes.getLoginRoute(), queryParameters: {'redirect': destination})}';
        expect(AppRoutes.startupRoute(location), AppRoutes.home, reason: destination);
        expect(AppRoutes.loginRouteFor(location), AppRoutes.getLoginRoute(), reason: destination);
      }
    }
  });

  testWidgets('Cold App Link waits for startup and resumes after login', (tester) async {
    final routes = _testRouter(initialLocation: 'https://messpilot.goraso.com/notices/42?source=shared');
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
    await tester.pumpAndSettle();
    expect(routes.routerDelegate.currentConfiguration.uri.path, AppRoutes.getSplashRoute());
    expect(initialDestination, '/notices/42?source=shared');

    appStartupComplete = true;
    routes.go(initialDestination);
    await tester.pumpAndSettle();
    final login = routes.routerDelegate.currentConfiguration.uri;
    expect(login.path, AppRoutes.getLoginRoute());
    expect(login.queryParameters['redirect'], '/notices/42?source=shared');

    await preferences.setString(AppConstants.tokenKey, 'test-token');
    routes.go(AppRoutes.startupRoute(login.queryParameters['redirect']!));
    await tester.pumpAndSettle();
    expect(routes.routerDelegate.currentConfiguration.uri.toString(), '/notices/42?source=shared');
  });

  testWidgets('Delayed iOS links retain the latest destination while splash is open', (tester) async {
    final routes = _testRouter();
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
    await tester.pumpAndSettle();

    await _sendLink(tester, routes, 'https://messpilot.goraso.com/notices/41');
    await _sendLink(tester, routes, 'https://messpilot.goraso.com/notices/42?source=latest');
    expect(routes.routerDelegate.currentConfiguration.uri.path, AppRoutes.getSplashRoute());
    expect(initialDestination, '/notices/42?source=latest');
    expect(appStartupComplete, isFalse);
  });

  testWidgets('Warm App Link opens its destination for a signed-in user', (tester) async {
    await preferences.setString(AppConstants.tokenKey, 'test-token');
    appStartupComplete = true;
    final routes = _testRouter(initialLocation: AppRoutes.home);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
    await tester.pumpAndSettle();

    await _sendLink(tester, routes, 'https://messpilot.goraso.com/notices/42?tab=history');
    expect(routes.routerDelegate.currentConfiguration.uri.toString(), '/notices/42?tab=history');
  });

  testWidgets('Warm App Link requires login before rendering a protected route', (tester) async {
    appStartupComplete = true;
    final routes = _testRouter(initialLocation: AppRoutes.getLoginRoute());
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
    await tester.pumpAndSettle();

    await _sendLink(tester, routes, 'https://messpilot.goraso.com/notices/42');
    final login = routes.routerDelegate.currentConfiguration.uri;
    expect(login.path, AppRoutes.getLoginRoute());
    expect(login.queryParameters['redirect'], '/notices/42');
    expect(find.text('/notices/42'), findsNothing);
  });

  for (final gate in [AppRoutes.maintenance, AppRoutes.updateRequired]) {
    testWidgets('App Link cannot bypass $gate', (tester) async {
      final routes = _testRouter(initialLocation: gate);
      addTearDown(routes.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
      await tester.pumpAndSettle();

      await _sendLink(tester, routes, 'https://messpilot.goraso.com/notices/42');
      expect(routes.routerDelegate.currentConfiguration.uri.path, gate);
      expect(initialDestination, '/notices/42');
      expect(appStartupComplete, isFalse);
    });
  }

  testWidgets('Public auth and help pages remain available after startup', (tester) async {
    appStartupComplete = true;
    final routes = _testRouter(initialLocation: AppRoutes.getLoginRoute());
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
    await tester.pumpAndSettle();

    for (final path in [AppRoutes.register, AppRoutes.forgotPassword, AppRoutes.privacyPolicy, AppRoutes.termsAndConditions, AppRoutes.faq, AppRoutes.support, AppRoutes.getLoginRoute()]) {
      routes.go(path);
      await tester.pumpAndSettle();
      expect(routes.routerDelegate.currentConfiguration.uri.path, path);
    }
  });

  testWidgets('Startup reads the latest pending link after awaiting app version', (tester) async {
    await preferences.setString(AppConstants.tokenKey, 'test-token');
    final routes = _testRouter();
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routes));
    await tester.pumpAndSettle();

    initialDestination = '/notices/41';
    final opening = openApp(tester.element(find.text(AppRoutes.getSplashRoute())), const ConfigEntity(latestVersion: '1.0.0', minimumVersion: '1.0.0'));
    initialDestination = '/notices/42?source=latest';
    await opening;
    await tester.pumpAndSettle();
    expect(routes.routerDelegate.currentConfiguration.uri.toString(), '/notices/42?source=latest');
    expect(appStartupComplete, isTrue);
  });

  testWidgets('Returning to splash resumes a pending link when app config is already loaded', (tester) async {
    await preferences.setString(AppConstants.tokenKey, 'test-token');
    initialDestination = '/notices/42';
    appStartupComplete = true;
    final splashBloc = _LoadedSplashBloc();
    addTearDown(splashBloc.close);
    final routes = GoRouter(
      initialLocation: AppRoutes.home,
      overridePlatformDefaultLocation: true,
      redirect: appRouteRedirect,
      routes: [
        GoRoute(path: AppRoutes.home, builder: _routeScreen),
        GoRoute(path: AppRoutes.getSplashRoute(), builder: (context, state) => const SplashScreen()),
        GoRoute(path: AppRoutes.noticeDetails, builder: _routeScreen),
      ],
    );
    addTearDown(routes.dispose);
    await tester.pumpWidget(BlocProvider<SplashBloc>.value(value: splashBloc, child: MaterialApp.router(
      routerConfig: routes,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    )));
    await tester.pumpAndSettle();

    routes.go(AppRoutes.getSplashRoute());
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(routes.routerDelegate.currentConfiguration.uri.path, '/notices/42');
    expect(appStartupComplete, isTrue);
    expect(splashBloc.configRequests, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
