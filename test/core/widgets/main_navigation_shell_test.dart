import 'dart:async';

import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/widgets/animated_bottom_nav_bar.dart';
import 'package:mess_pilot/core/widgets/main_navigation_shell.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _TestAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _TestAuthBloc() : super(const AuthState.authenticated(UserEntity(id: '1', email: 'member@example.com', name: 'Member'))) {
    on<AuthEvent>((event, emit) {});
  }

  void updateUser(UserEntity user) => emit(AuthState.authenticated(user));

  @override
  Future<void> refreshProfile() async {}
}

const _routes = [AppRoutes.home, AppRoutes.meals, AppRoutes.deposits, AppRoutes.costs, AppRoutes.profile];

GoRouter _createRouter({String initialLocation = AppRoutes.home}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainNavigationShell(navigationShell: navigationShell),
      branches: [
        for (final route in _routes)
          StatefulShellBranch(routes: [GoRoute(path: route, builder: (context, state) => Scaffold(body: SizedBox.expand(key: ValueKey(route))))]),
      ],
    ),
    GoRoute(path: AppRoutes.settings, builder: (context, state) => const Scaffold(body: Text('Settings page'))),
  ],
);

Widget _app(GoRouter testRouter, AuthBloc authBloc, {String language = 'en', double textScale = 1, double keyboardHeight = 0}) => BlocProvider<AuthBloc>.value(
  value: authBloc,
  child: MaterialApp.router(
    theme: AppTheme.light,
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: testRouter,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
      child: child!,
    ),
  ),
);

void main() {
  late _TestAuthBloc authBloc;

  setUp(() => authBloc = _TestAuthBloc());
  tearDown(() async => authBloc.close());

  testWidgets('Navbar remains on every destination and is absent on other routes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final testRouter = _createRouter();
    addTearDown(testRouter.dispose);
    await tester.pumpWidget(_app(testRouter, authBloc));
    await tester.pumpAndSettle();

    for (var index = 0; index < _routes.length; index++) {
      await tester.tap(find.descendant(of: find.byType(AnimatedBottomNavBar), matching: find.byType(InkWell)).at(index));
      await tester.pumpAndSettle();
      expect(testRouter.routeInformationProvider.value.uri.path, _routes[index]);
      expect(tester.widget<AnimatedBottomNavBar>(find.byType(AnimatedBottomNavBar)).currentIndex, index);
      expect(find.byKey(ValueKey(_routes[index])), findsOneWidget);
      final contentRect = tester.getRect(find.byKey(ValueKey(_routes[index])));
      final navRect = tester.getRect(find.byType(AnimatedBottomNavBar));
      expect(contentRect.bottom, greaterThan(navRect.top), reason: 'The navbar must be an overlay on top of the body.');
      expect(navRect.bottom, closeTo(tester.view.physicalSize.height / tester.view.devicePixelRatio, 0.01));
      expect(tester.takeException(), isNull);
    }

    unawaited(testRouter.push<void>(AppRoutes.settings));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedBottomNavBar), findsNothing);
    testRouter.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedBottomNavBar>(find.byType(AnimatedBottomNavBar)).currentIndex, 4);
  });

  testWidgets('Navbar hides when scrolling down and shows again when scrolling up', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testRouter = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainNavigationShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => Scaffold(
                    body: ListView(children: [for (var i = 0; i < 40; i++) SizedBox(height: 80, child: Text('Item $i'))]),
                  ),
                ),
              ],
            ),
            for (final route in _routes.skip(1)) StatefulShellBranch(routes: [GoRoute(path: route, builder: (context, state) => const Scaffold(body: SizedBox.shrink()))]),
          ],
        ),
      ],
    );
    addTearDown(testRouter.dispose);
    await tester.pumpWidget(_app(testRouter, authBloc));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedBottomNavBar>(find.byType(AnimatedBottomNavBar)).visible, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedBottomNavBar>(find.byType(AnimatedBottomNavBar)).visible, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedBottomNavBar>(find.byType(AnimatedBottomNavBar)).visible, isTrue);
  });

  testWidgets('Navbar fits narrow screens, translations and large text with a round avatar', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final testRouter = _createRouter(initialLocation: AppRoutes.profile);
    addTearDown(testRouter.dispose);

    for (final width in [320.0, 375.0, 420.0, 800.0]) {
      tester.view.physicalSize = Size(width, 800);
      for (final language in ['en', 'bn', 'ar']) {
        for (final textScale in [1.0, 2.0]) {
          await tester.pumpWidget(_app(testRouter, authBloc, language: language, textScale: textScale));
          await tester.pumpAndSettle();
          for (var index = 0; index < _routes.length; index++) {
            testRouter.go(_routes[index]);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$width / $language / $textScale / ${_routes[index]}');
            final avatar = tester.getSize(find.descendant(of: find.byType(AnimatedBottomNavBar), matching: find.byType(ClipOval)));
            expect(avatar.width, avatar.height);
            final buttons = find.descendant(of: find.byType(AnimatedBottomNavBar), matching: find.byType(InkWell));
            final firstButton = tester.getRect(buttons.first);
            final inactiveWidth = tester.getRect(buttons.at(index == 0 ? 1 : 0)).width;
            for (var button = 0; button < 5; button++) {
              final buttonRect = tester.getRect(buttons.at(button));
              expect(buttonRect.width, closeTo(inactiveWidth * (button == index ? 2 : 1), 0.01));
              final symbol = find.descendant(of: buttons.at(button), matching: find.byType(button == 4 ? ClipOval : Icon));
              final symbolRect = tester.getRect(symbol.first);
              expect(symbolRect.center.dy, buttonRect.center.dy);
              if (button != index) expect(symbolRect.center.dx, closeTo(buttonRect.center.dx, 0.01));
            }
            for (var button = 1; button < 5; button++) {
              final previousButton = tester.getRect(buttons.at(button - 1));
              final currentButton = tester.getRect(buttons.at(button));
              expect(previousButton.overlaps(currentButton), isFalse);
              expect(currentButton.height, firstButton.height);
              expect(currentButton.center.dy, firstButton.center.dy);
              expect((currentButton.center.dx - previousButton.center.dx).abs() - (currentButton.width + previousButton.width) / 2, closeTo(8, 0.01));
            }
          }
        }
      }
    }
  });

  testWidgets('Navbar hides for keyboard and desktop and updates the signed-in avatar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final testRouter = _createRouter(initialLocation: AppRoutes.deposits);
    addTearDown(testRouter.dispose);
    await tester.pumpWidget(_app(testRouter, authBloc, keyboardHeight: 300));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedBottomNavBar), findsNothing);

    await tester.pumpWidget(_app(testRouter, authBloc));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedBottomNavBar), findsOneWidget);
    authBloc.updateUser(const UserEntity(id: '1', email: 'member@example.com', name: 'Member', photoUrl: 'https://example.com/avatar.png'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedBottomNavBar>(find.byType(AnimatedBottomNavBar)).items.last.profileImageUrl, 'https://example.com/avatar.png');
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedBottomNavBar), findsNothing);
  });
}
