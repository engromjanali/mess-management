import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/auth/presentation/screens/edit_profile_screen.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

class _FakeAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _FakeAuthBloc(UserEntity user) : super(AuthState.authenticated(user)) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  Future<void> refreshProfile() async {}
}

class _FakeUpdateProfileUseCase implements UpdateProfileUseCase {
  final UserEntity user;
  _FakeUpdateProfileUseCase(this.user);

  @override
  ResultFuture<UserEntity> call(UpdateProfileParams params) async {
    return Result.success(data: UserEntity(id: user.id, name: params.fullName, email: user.email, phone: user.phone));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const user = UserEntity(
    id: 'u1',
    name: 'Romjan',
    email: 'romjan@example.com',
    phone: '01700000000',
  );

  testWidgets('Saving profile when cannot pop routes to home without GoError', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    if (getIt.isRegistered<UpdateProfileUseCase>()) {
      getIt.unregister<UpdateProfileUseCase>();
    }
    getIt.registerSingleton<UpdateProfileUseCase>(_FakeUpdateProfileUseCase(user));
    addTearDown(() => getIt.unregister<UpdateProfileUseCase>());

    final router = GoRouter(
      initialLocation: AppRoutes.editProfile,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>(
        create: (_) => _FakeAuthBloc(user),
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsWidgets);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('Saving profile when can pop pops to previous screen', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    if (getIt.isRegistered<UpdateProfileUseCase>()) {
      getIt.unregister<UpdateProfileUseCase>();
    }
    getIt.registerSingleton<UpdateProfileUseCase>(_FakeUpdateProfileUseCase(user));
    addTearDown(() => getIt.unregister<UpdateProfileUseCase>());

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push(AppRoutes.editProfile),
              child: const Text('Go Edit'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<AuthBloc>(
        create: (_) => _FakeAuthBloc(user),
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsWidgets);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Go Edit'), findsOneWidget);
  });
}
