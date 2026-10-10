import 'dart:ui';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/screens/maintenance_screen.dart';
import 'package:clean_boilerplate/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  _ThemeBloc() : super(const ThemeState.system()) {
    on<ThemeEvent>((event, emit) {});
  }
}

class _LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> implements LocalizationBloc {
  _LocalizationBloc() : super(const LocalizationState.initial(Locale('en'))) {
    on<LocalizationEvent>((event, emit) {});
  }
}

class _AuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _AuthBloc() : super(const AuthState.initial()) {
    on<AuthEvent>((event, emit) {});
  }
}

class _SplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _SplashBloc() : super(const SplashState.loading()) {
    on<SplashEvent>((event, emit) {});
  }

  void enableMaintenance() => emit(const SplashState.loaded(ConfigEntity(latestVersion: '1.0.0', minimumVersion: '1.0.0', maintenanceMode: true)));
}

void main() {
  testWidgets('Browser focus before layout and maintenance on a non-root route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    getIt.registerFactory<ThemeBloc>(() => _ThemeBloc());
    getIt.registerFactory<LocalizationBloc>(() => _LocalizationBloc());
    getIt.registerFactory<AuthBloc>(() => _AuthBloc());
    final splashBloc = _SplashBloc();
    getIt.registerSingleton<SplashBloc>(splashBloc);
    addTearDown(() => getIt.reset());

    router.go(AppRoutes.getLoginRoute());
    await tester.pumpWidget(const MyApp(), phase: EnginePhase.build);
    tester.binding.handleViewFocusChanged(ViewFocusEvent(viewId: tester.view.viewId, state: ViewFocusState.focused, direction: ViewFocusDirection.forward));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    splashBloc.enableMaintenance();
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, AppRoutes.maintenance);
    expect(find.byType(MaintenanceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !kIsWeb);
}
