import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _routeScreen(BuildContext context, GoRouterState state) => Scaffold(body: Text(state.uri.toString()));

GoRouter _testRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  overridePlatformDefaultLocation: true,
  redirect: appRouteRedirect,
  routes: [
    for (final path in [AppRoutes.home, AppRoutes.getSplashRoute(), AppRoutes.getLoginRoute(), AppRoutes.maintenance, AppRoutes.updateRequired, AppRoutes.noticeDetails])
      GoRoute(path: path, builder: _routeScreen),
  ],
  errorBuilder: (context, state) => const Scaffold(body: Text('route-error')),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(preferences);
    initialDestination = AppRoutes.home;
    appStartupComplete = false;
  });

  tearDown(() async {
    initialDestination = AppRoutes.home;
    appStartupComplete = false;
    await getIt.reset();
  });

  test('Malformed UTF-8 login redirects fall back safely during startup', () {
    for (final suffix in ['%FF', '%E0%A4%A', '%C0%AFnotices%2F42']) {
      for (final prefix in ['', 'https://messpilot.goraso.com']) {
        final location = '$prefix/login?redirect=$suffix';
        expect(AppRoutes.startupRoute(location), AppRoutes.home, reason: location);
        expect(AppRoutes.loginRouteFor(location), AppRoutes.getLoginRoute(), reason: location);
      }
    }
  });

  test('Oversized URL ports fall back safely instead of throwing during validation', () {
    const location = 'https://messpilot.goraso.com:999999999999999999999/notices/42';
    expect(AppRoutes.linkLocation(location), AppRoutes.home);
    expect(AppRoutes.startupRoute(location), AppRoutes.home);
  });

  testWidgets('Cold malformed login URL reaches splash instead of an exception screen', (tester) async {
    final routes = _testRouter('/login?redirect=%FF');
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouterConfiguration(routes)));
    await tester.pumpAndSettle();

    expect(routes.routerDelegate.currentConfiguration.uri.path, AppRoutes.getSplashRoute());
    expect(initialDestination, AppRoutes.home);
    expect(find.text('route-error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Warm malformed login URL falls back without an exception screen', (tester) async {
    await preferences.setString(AppConstants.tokenKey, 'test-token');
    appStartupComplete = true;
    final routes = _testRouter(AppRoutes.home);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouterConfiguration(routes)));
    await tester.pumpAndSettle();

    await routes.routeInformationProvider.didPushRouteInformation(RouteInformation(uri: Uri.parse('https://messpilot.goraso.com/login?redirect=%FF')));
    await tester.pumpAndSettle();
    expect(routes.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
    expect(find.text('route-error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Warm malformed notice path is rejected before route matching', (tester) async {
    await preferences.setString(AppConstants.tokenKey, 'test-token');
    appStartupComplete = true;
    final routes = _testRouter(AppRoutes.home);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouterConfiguration(routes)));
    await tester.pumpAndSettle();

    await routes.routeInformationProvider.didPushRouteInformation(RouteInformation(uri: Uri.parse('https://messpilot.goraso.com/notices/%FF')));
    await tester.pumpAndSettle();
    expect(routes.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
    expect(find.text('route-error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Parser wrapper preserves browser history query, fragment, and route state', (tester) async {
    await preferences.setString(AppConstants.tokenKey, 'test-token');
    appStartupComplete = true;
    final routes = _testRouter(AppRoutes.home);
    final configuration = appRouterConfiguration(routes);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: configuration));
    await tester.pumpAndSettle();

    const destination = '/notices/42?label=%E0%A6%96&tab=history#details';
    const extra = {'source': 'shared'};
    routes.go(destination, extra: extra);
    await tester.pumpAndSettle();
    final restored = configuration.routeInformationParser!.restoreRouteInformation(routes.routerDelegate.currentConfiguration)!;
    expect(restored.uri.toString(), destination);
    expect(restored.state, isNotNull);

    routes.go(AppRoutes.home);
    await tester.pumpAndSettle();
    await routes.routeInformationProvider.didPushRouteInformation(restored);
    await tester.pumpAndSettle();
    expect(routes.routerDelegate.currentConfiguration.uri.toString(), destination);
    expect(routes.routerDelegate.currentConfiguration.extra, extra);
    expect(find.text(destination), findsOneWidget);
    expect(find.text('route-error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Programmatic navigation can move maintenance to the required update gate', (tester) async {
    final routes = _testRouter(AppRoutes.maintenance);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouterConfiguration(routes)));
    await tester.pumpAndSettle();

    routes.go(AppRoutes.updateRequired);
    await tester.pumpAndSettle();
    expect(routes.routerDelegate.currentConfiguration.uri.path, AppRoutes.updateRequired);
    expect(appStartupComplete, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('External startup and gate URLs cannot activate gates in an unblocked app', (tester) async {
    await preferences.setString(AppConstants.tokenKey, 'test-token');
    appStartupComplete = true;
    final routes = _testRouter(AppRoutes.home);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouterConfiguration(routes)));
    await tester.pumpAndSettle();

    for (final target in [AppRoutes.getSplashRoute(), AppRoutes.maintenance, AppRoutes.updateRequired]) {
      for (final location in ['https://messpilot.goraso.com$target', 'https://messpilot.goraso.com/#$target']) {
        await routes.routeInformationProvider.didPushRouteInformation(RouteInformation(uri: Uri.parse(location)));
        await tester.pumpAndSettle();
        expect(routes.routerDelegate.currentConfiguration.uri.path, AppRoutes.home, reason: location);
        expect(appStartupComplete, isTrue);
        expect(find.text('route-error'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  for (final gate in [AppRoutes.maintenance, AppRoutes.updateRequired]) {
    testWidgets('Warm links cannot switch the active $gate gate', (tester) async {
      initialDestination = '/notices/42';
      final routes = _testRouter(gate);
      addTearDown(routes.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouterConfiguration(routes)));
      await tester.pumpAndSettle();

      for (final target in [AppRoutes.getSplashRoute(), gate == AppRoutes.maintenance ? AppRoutes.updateRequired : AppRoutes.maintenance]) {
        for (final location in ['https://messpilot.goraso.com$target', 'https://messpilot.goraso.com/#$target']) {
          await routes.routeInformationProvider.didPushRouteInformation(RouteInformation(uri: Uri.parse(location)));
          await tester.pumpAndSettle();
          expect(routes.routerDelegate.currentConfiguration.uri.path, gate, reason: location);
          expect(initialDestination, '/notices/42');
          expect(appStartupComplete, isFalse);
          expect(find.text('route-error'), findsNothing);
        }
      }
    });
  }
}
