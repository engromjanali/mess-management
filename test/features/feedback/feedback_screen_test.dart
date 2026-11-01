import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/core/widgets/web_page_title_bar.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:mess_pilot/features/home/presentation/widgets/main_top_bar.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FeedbackAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _FeedbackAuthBloc() : super(const AuthState.initial());

  @override
  Future<void> refreshProfile() async {}
}

class _FeedbackThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  _FeedbackThemeBloc() : super(const ThemeState.light());
}

class _FeedbackLocaleBloc extends Bloc<LocalizationEvent, LocalizationState> implements LocalizationBloc {
  _FeedbackLocaleBloc() : super(const LocalizationState.initial(Locale('en')));
}

class _FeedbackSplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _FeedbackSplashBloc() : super(const SplashState.loading());
}

void main() {
  testWidgets('Feedback page uses the shared responsive app bars and full-width footer without overflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.extra['sensitive'], isTrue);
      handler.resolve(Response(requestOptions: options, data: {
        'data': [{
          'id': 1,
          'description': 'Public feedback from a member',
          'images': [],
          'author_name': 'Member',
          'author_photo_url': null,
          'created_at': '2026-10-25T10:00:00Z',
        }],
        'next_page': null,
      }));
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() { getIt.unregister<ApiClient>(); dio.close(); });


    for (final width in [320.0, 700.0, 900.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1100);
      for (final locale in ['en', 'bn', 'ar']) {
        await tester.pumpWidget(MultiBlocProvider(
          key: ValueKey('$width-$locale'),
          providers: [
            BlocProvider<AuthBloc>(create: (_) => _FeedbackAuthBloc()),
            BlocProvider<ThemeBloc>(create: (_) => _FeedbackThemeBloc()),
            BlocProvider<LocalizationBloc>(create: (_) => _FeedbackLocaleBloc()),
            BlocProvider<SplashBloc>(create: (_) => _FeedbackSplashBloc()),
            BlocProvider<RoleCubit>(create: (context) => RoleCubit(context.read<AuthBloc>())),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: width == 320 ? (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!) : null,
            home: const FeedbackScreen(),
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Public feedback from a member'), findsOneWidget);
        if (width > 850) {
          expect(find.byType(AppBar), findsNothing);
          expect(find.byType(MainTopBar), findsOneWidget);
          expect(find.byType(WebPageTitleBar), findsOneWidget);
          expect(tester.getRect(find.byType(MainTopBar)).width, width);
          final position = Scrollable.of(tester.element(find.byType(AppFooter))).position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          final footer = tester.getRect(find.byType(AppFooter));
          expect(footer.left, 0);
          expect(footer.width, width);
          expect(footer.bottom, closeTo(1100, 1));
        } else {
          expect(find.byType(AppBar), findsOneWidget);
          expect(find.byType(MainTopBar), findsNothing);
          expect(find.byType(WebPageTitleBar), findsNothing);
          expect(find.byType(AppFooter), findsNothing);
        }
        expect(tester.takeException(), isNull, reason: '$width $locale');
      }
    }
  });

  testWidgets('Allows toggling comments and posting a new comment', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        expect(options.extra['sensitive'], isTrue);
        if (options.method == 'GET' && options.path == '/api/v1/user/feedbacks') {
          return handler.resolve(Response(
            requestOptions: options,
            data: {
              'data': [
                {
                  'id': 1,
                  'description': 'Feature idea for pilot',
                  'images': [],
                  'author_name': 'Tester',
                  'author_photo_url': null,
                  'comments_count': 11,
                  'created_at': '2026-10-25T10:00:00Z',
                }
              ],
              'next_page': null,
            },
          ));
        }
        if (options.method == 'GET' && options.path == '/api/v1/user/feedbacks/1/comments') {
          final secondPage = options.queryParameters['page'] == 2;
          return handler.resolve(Response(
            requestOptions: options,
            data: {
              'data': secondPage ? [
                {
                  'id': 20,
                  'feedback': 1,
                  'comment': 'Last paginated comment',
                  'image_url': null,
                  'author_name': 'Reviewer',
                  'author_photo_url': null,
                  'is_author': false,
                  'created_at': '2026-10-25T10:30:00Z',
                }
              ] : List.generate(10, (index) => {
                'id': index + 10,
                'feedback': 1,
                'comment': index == 0 ? 'Existing comment on idea' : 'Earlier comment $index',
                'image_url': null,
                'author_name': 'Reviewer',
                'author_photo_url': null,
                'is_author': false,
                'created_at': '2026-10-25T10:30:00Z',
              }),
              'next_page': secondPage ? null : 2,
            },
          ));
        }
        if (options.method == 'POST' && options.path == '/api/v1/user/feedbacks/1/comments') {
          return handler.resolve(Response(
            requestOptions: options,
            data: {
              'id': 11,
              'feedback': 1,
              'comment': 'New user reply',
              'image_url': null,
              'author_name': 'Current User',
              'author_photo_url': null,
              'is_author': true,
              'created_at': '2026-10-25T11:00:00Z',
            },
          ));
        }
        handler.reject(DioException(requestOptions: options));
      },
    ));

    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() {
      getIt.unregister<ApiClient>();
      dio.close();
    });

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => _FeedbackAuthBloc()),
        BlocProvider<ThemeBloc>(create: (_) => _FeedbackThemeBloc()),
        BlocProvider<LocalizationBloc>(create: (_) => _FeedbackLocaleBloc()),
        BlocProvider<SplashBloc>(create: (_) => _FeedbackSplashBloc()),
        BlocProvider<RoleCubit>(create: (context) => RoleCubit(context.read<AuthBloc>())),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FeedbackScreen(),
      ),
    ));

    await tester.pumpAndSettle();
    expect(find.text('Feature idea for pilot'), findsOneWidget);
    expect(find.text('11 comments'), findsOneWidget);

    // Tap comment button to expand
    await tester.tap(find.text('11 comments'));
    await tester.pumpAndSettle();

    // Verify existing comment is loaded
    expect(find.text('Existing comment on idea'), findsOneWidget);
    final loadMore = find.widgetWithText(TextButton, 'Load more');
    await tester.ensureVisible(loadMore);
    await tester.tap(loadMore);
    await tester.pumpAndSettle();
    expect(find.text('Last paginated comment'), findsOneWidget);

    // Write and send a comment
    final commentField = find.byType(TextField).last;
    await tester.ensureVisible(commentField);
    await tester.enterText(commentField, 'New user reply');
    await tester.pumpAndSettle();

    final sendButton = find.byIcon(Icons.send_rounded).last;
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('New user reply'), findsOneWidget);
    expect(find.text('12 comments'), findsOneWidget);
  });
}
