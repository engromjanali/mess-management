import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';
import 'package:clean_boilerplate/features/notice/presentation/screens/notice_details_screen.dart';
import 'package:clean_boilerplate/features/notice/presentation/widgets/notice_card.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';

class _AuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _AuthBloc() : super(const AuthState.initial());
  @override
  Future<void> refreshProfile() async {}
}

class _ThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  _ThemeBloc() : super(const ThemeState.light());
}

class _LocaleBloc extends Bloc<LocalizationEvent, LocalizationState> implements LocalizationBloc {
  _LocaleBloc() : super(const LocalizationState.initial(Locale('en')));
}

class _SplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _SplashBloc() : super(const SplashState.loading());
}

void main() {
  testWidgets('Desktop notice details include a footer without overflow in supported locales', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final height in [600.0, 900.0, 1600.0]) {
      tester.view.physicalSize = Size(1440, height);
    for (final language in ['en', 'bn', 'ar']) {
      await tester.pumpWidget(MultiBlocProvider(providers: [
        BlocProvider<AuthBloc>(create: (_) => _AuthBloc()),
        BlocProvider<ThemeBloc>(create: (_) => _ThemeBloc()),
        BlocProvider<LocalizationBloc>(create: (_) => _LocaleBloc()),
        BlocProvider<SplashBloc>(create: (_) => _SplashBloc()),
      ], child: MaterialApp(
        theme: AppTheme.light,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
        home: NoticeDetailsScreen(notice: NoticeEntity(id: '1', title: 'Notice', description: 'Full details', createdAt: DateTime(2026, 10, 22))),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(AppFooter), findsOneWidget);
      final position = Scrollable.of(tester.element(find.byType(AppFooter))).position;
      if (height == 1600) expect(position.maxScrollExtent, 0);
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(AppFooter)).bottom, closeTo(height, 1), reason: '$language $height');
      expect(tester.takeException(), isNull, reason: '$language $height');
    }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Notice preview opens full details and fits large text on a phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notice = NoticeEntity(id: '1', title: 'Long notice title ' * 12, description: 'Full notice content ' * 80, createdAt: DateTime(2026, 10, 22), pinned: true);
    final routes = GoRouter(initialLocation: AppRoutes.notices, routes: [
      GoRoute(path: AppRoutes.notices, builder: (context, state) => Scaffold(body: SingleChildScrollView(child: NoticeCard(
        notice: notice,
        showActions: true,
        onTap: () => context.go(AppRoutes.getNoticeDetailsRoute(notice.id), extra: notice),
      ))), routes: [
      GoRoute(path: ':id', builder: (context, state) => NoticeDetailsScreen(noticeId: state.pathParameters['id'], notice: state.extra as NoticeEntity)),
      ]),
    ]);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: routes,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(notice.title)).maxLines, 2);
    expect(tester.widget<Text>(find.text(notice.description)).maxLines, 3);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(notice.title));
    await tester.pumpAndSettle();
    expect(find.byType(NoticeDetailsScreen), findsOneWidget);
    expect(routes.routeInformationProvider.value.uri.path, '/notices/1');
    expect(tester.widget<Text>(find.text(notice.description)).maxLines, isNull);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(NoticeDetailsScreen), findsNothing);
  });
}
