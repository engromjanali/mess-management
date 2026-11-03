@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:mess_pilot/features/splash/domain/entities/config_entity.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mess_pilot/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

@JS('window.history.replaceState')
external void _replaceBrowserUrl(JSAny? data, String title, String url);

class _RootPlatformLocation extends ui_web.BrowserPlatformLocation {
  const _RootPlatformLocation();

  @override
  String getBaseHref() => '/';
}

class _ThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  _ThemeBloc() : super(const ThemeState.light()) {
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

  @override
  Future<void> refreshProfile() async {}
}

class _SplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _SplashBloc() : super(const SplashState.loaded(ConfigEntity(latestVersion: '1.0.0', minimumVersion: '1.0.0'))) {
    on<SplashEvent>((event, emit) {});
  }
}

void main() {
  // The non-web analyzer resolves a different PlatformLocation stub.
  setUrlStrategy(PathUrlStrategy(const _RootPlatformLocation() as dynamic));
  testWidgets('Browser cold link is captured before splash replaces the real URL', (tester) async {
    final originalUrl = Uri.base.toString();
    addTearDown(() => _replaceBrowserUrl(null, '', originalUrl));
    _replaceBrowserUrl(null, '', '/notices/42?source=shared');
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    getIt.registerFactory<ThemeBloc>(() => _ThemeBloc());
    getIt.registerFactory<LocalizationBloc>(() => _LocalizationBloc());
    getIt.registerFactory<AuthBloc>(() => _AuthBloc());
    getIt.registerFactory<SplashBloc>(() => _SplashBloc());
    addTearDown(() => getIt.reset());
    PackageInfo.setMockInitialValues(appName: 'Mess Pilot', packageName: 'com.goraso.messpilot', version: '1.0.0', buildNumber: '1', buildSignature: '');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final location = router.routerDelegate.currentConfiguration.uri;
    expect(location.path, AppRoutes.getLoginRoute());
    expect(location.queryParameters['redirect'], '/notices/42?source=shared');
    expect(initialDestination, '/notices/42?source=shared');
    expect(appStartupComplete, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
