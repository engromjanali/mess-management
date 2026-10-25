import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/notifications/presentation/screens/notification_screen.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  testWidgets('Inbox and season warning fit narrow screens in every locale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    final title = List.filled(12, 'Notification title').join(' ');
    final description = List.filled(40, 'Notification description').join(' ');
    final item = {'id': 1, 'title': title, 'description': description, 'season_name': 'Season one', 'created_at': '2026-10-25T10:00:00Z', 'read': false};
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(requestOptions: options, data: options.method == 'POST' ? {...item, 'status': 'change_season'} : {'data': [Map<String, dynamic>.from(item)], 'next': null}));
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() => getIt.reset());
    for (final locale in ['en', 'bn', 'ar']) {
      await tester.pumpWidget(MaterialApp(
        key: ValueKey(locale),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
        home: const NotificationScreen(),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(title), 180, scrollable: find.byType(Scrollable).first);
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull, reason: locale);
      await tester.ensureVisible(find.text(title));
      tester.widget<InkWell>(find.descendant(of: find.byType(Card), matching: find.byType(InkWell)).first).onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(description), findsNWidgets(2));
      expect(tester.takeException(), isNull, reason: locale);
    }
  });

  testWidgets('Notification grid uses one or two columns across screen sizes without overflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    var itemCount = 3;
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(requestOptions: options, data: {'data': List.generate(itemCount, (index) => {
        'id': index + 1, 'title': 'Notification $index', 'description': 'Short notification message',
        'season_name': 'Season one', 'created_at': '2026-10-25T10:00:00Z', 'read': false,
      }), 'next': null}));
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() => getIt.reset());
    for (final width in [320.0, 700.0, 900.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1000);
      for (final count in [0, 3, 25]) {
      itemCount = count;
      for (final locale in ['en', 'bn', 'ar']) {
        await tester.pumpWidget(MultiBlocProvider(key: ValueKey('$width-$count-$locale'), providers: [
          BlocProvider<AuthBloc>(create: (_) => _AuthBloc()),
          BlocProvider<ThemeBloc>(create: (_) => _ThemeBloc()),
          BlocProvider<LocalizationBloc>(create: (_) => _LocaleBloc()),
          BlocProvider<SplashBloc>(create: (_) => _SplashBloc()),
          BlocProvider<RoleCubit>(create: (context) => RoleCubit(context.read<AuthBloc>())),
        ], child: MaterialApp(
          theme: AppTheme.light,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationScreen(),
        )));
        await tester.pumpAndSettle();
        if (count > 0) {
        final first = tester.getRect(find.text('Notification 0'));
        final second = tester.getRect(find.text('Notification 1'));
        if (width > 850) {
          expect(second.top, first.top, reason: '$width $locale');
          expect(second.left, isNot(first.left));
        } else {
          expect(second.top, greaterThan(first.top), reason: '$width $locale');
          expect(second.left, first.left);
        }
        }
        if (width > 850) {
          final position = Scrollable.of(tester.element(find.byType(AppFooter))).position;
          if (width == 1440 && count < 4) expect(position.maxScrollExtent, 0);
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          final footer = tester.getRect(find.byType(AppFooter));
          expect(footer.bottom, closeTo(1000, 1), reason: '$width $count $locale');
          expect(footer.left, 0);
          expect(footer.width, width);
        }
        final context = tester.element(find.byType(NotificationScreen));
        expect(find.text(AppLocalizations.of(context).notificationInboxTitle), findsNothing);
        expect(tester.takeException(), isNull, reason: '$width $locale');
      }
    }
    }
  });
}
