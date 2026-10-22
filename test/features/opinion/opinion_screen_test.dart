import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/opinion/presentation/screens/opinion_screen.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpinionTestAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  OpinionTestAuthBloc({bool admin = false}) : super(AuthState.authenticated(UserEntity(id: '1', email: 'member@example.com', name: 'Member', activeMessId: 99, role: admin ? 'manager' : 'member'))) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  Future<void> refreshProfile() async {}
}

class OpinionTestLocaleBloc extends Bloc<LocalizationEvent, LocalizationState> implements LocalizationBloc {
  OpinionTestLocaleBloc(String language) : super(LocalizationState.initial(Locale(language))) {
    on<LocalizationEvent>((event, emit) {});
  }
}

void main() {
  testWidgets('Season permissions, visibility and manual refresh fit mobile and desktop without polling', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    var canWrite = true;
    var expired = false;
    var visibility = 'after_publish';
    var requests = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.queryParameters.containsKey('mess_id'), isFalse);
      requests++;
      if (options.method == 'PATCH') {
        visibility = (options.data as Map<String, dynamic>)['visibility'] as String;
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'id': 10}));
        return;
      }
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'mess_id': 7, 'can_manage': true, 'can_create': true, 'next_page': null,
        'data': [{
          'id': 10, 'season_id': 4, 'season_name': 'October', 'title': 'Season feedback', 'details': 'Feedback for this season',
          'start_date': '2000-01-01', 'end_date': expired ? '2000-01-02' : '2099-12-31', 'accepting_messages': true, 'visibility': visibility,
          'can_write': canWrite, 'opinion_count': 2, 'has_more_opinions': false,
          'opinions': [
            {'id': 20, 'period_id': 10, 'message': 'Published feedback', 'created_at': '2026-10-12T12:00:00Z', 'is_published': true},
            {'id': 21, 'period_id': 10, 'message': 'Private feedback', 'created_at': '2026-10-12T12:00:00Z', 'is_published': false},
          ],
        }],
      }));
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() { getIt.unregister<ApiClient>(); dio.close(); });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    for (final width in [320.0, 390.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1000);
      for (final language in ['en', 'bn', 'ar']) {
        for (final admin in [false, true]) {
          canWrite = true;
          expired = false;
          visibility = 'after_publish';
          final auth = OpinionTestAuthBloc(admin: admin);
          final role = RoleCubit(auth);
          final localization = OpinionTestLocaleBloc(language);
          await tester.pumpWidget(MultiBlocProvider(
            providers: [BlocProvider<RoleCubit>.value(value: role), BlocProvider<AuthBloc>.value(value: auth), BlocProvider<LocalizationBloc>.value(value: localization)],
            child: MaterialApp(
              theme: admin ? AppTheme.dark : AppTheme.light,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const OpinionScreen(),
            ),
          ));
          await tester.pumpAndSettle();
          expect(find.text('Published feedback'), admin ? findsOneWidget : findsNothing);
          expect(find.text('Private feedback'), admin ? findsOneWidget : findsNothing);
          expect(find.byType(FloatingActionButton), admin ? findsOneWidget : findsNothing);
          final input = tester.widget<TextField>(find.byType(TextField));
          expect(input.minLines, 2);
          expect(input.maxLines, 5);
          if (admin) {
            final local = AppLocalizations.of(tester.element(find.byType(OpinionScreen)));
            expect(find.widgetWithText(OutlinedButton, local.opinionPrivate), findsOneWidget);
          }
          expect(tester.takeException(), isNull, reason: '$width $language admin=$admin');
          canWrite = false;
          expired = false;
          visibility = 'realtime';
          final previousRequests = requests;
          await tester.pump(const Duration(seconds: 45));
          await tester.pumpAndSettle();
          expect(requests, previousRequests);
          expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await tester.pumpAndSettle();
          expect(requests, previousRequests);
          final refreshButton = find.byTooltip(AppLocalizations.of(tester.element(find.byType(OpinionScreen))).refresh);
          await tester.tap(refreshButton);
          await tester.pumpAndSettle();
          expect(requests, previousRequests + 1);
          expect(find.byType(TextField), findsNothing);
          expect(find.text(AppLocalizations.of(tester.element(find.byType(OpinionScreen))).opinionCurrentSeasonOnly), findsOneWidget);
          expect(find.text('Private feedback'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: '$width $language read only');
          if (admin) {
            expired = true;
            await tester.tap(refreshButton);
            await tester.pumpAndSettle();
            final local = AppLocalizations.of(tester.element(find.byType(OpinionScreen)));
            final publicButton = find.widgetWithText(OutlinedButton, local.opinionPublic);
            await tester.ensureVisible(publicButton);
            await tester.tap(publicButton);
            await tester.pumpAndSettle();
            expect(visibility, 'after_publish');
            final privateButton = find.widgetWithText(OutlinedButton, local.opinionPrivate);
            expect(privateButton, findsOneWidget);
            expect(find.byType(TextField), findsNothing);
            await tester.ensureVisible(privateButton);
            await tester.tap(privateButton);
            await tester.pumpAndSettle();
            expect(visibility, 'realtime');
            expect(publicButton, findsOneWidget);
            expect(find.byType(TextField), findsNothing);
            expect(tester.takeException(), isNull, reason: '$width $language visibility toggle after deadline');
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() async {
            await auth.close();
            await role.close();
            await localization.close();
          });
        }
      }
    }
  });
}
