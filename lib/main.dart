import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/helpers/auth_helper.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/role/role_switcher_fab.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/widgets/app_gate.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  // Show pushed routes (context.push) in the browser URL, so every screen has its own address.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Configure dependency injection
  await configureDependencies();

  // Session expired or token rejected: send the user back to login.
  getIt<ApiClient>().onUnauthorized = () {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    const authRoutes = [AppRoutes.register, AppRoutes.forgotPassword];
    if (path == AppRoutes.getLoginRoute() || authRoutes.contains(path)) return;
    router.go(AppRoutes.getLoginRoute());
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FocusTraversalPolicy _focusTraversalPolicy = kIsWeb ? WidgetOrderTraversalPolicy() : ReadingOrderTraversalPolicy();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Browser focus can arrive before the router overlay has a layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _focusTraversalPolicy = ReadingOrderTraversalPolicy());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ThemeBloc>()..add(const ThemeEvent.loadThemeMode())),
        BlocProvider(create: (context) => getIt<LocalizationBloc>()..add(const LocalizationEvent.loadLocale())),
        BlocProvider(create: (context) => getIt<SplashBloc>()..add(const SplashEvent.getConfig())),
        BlocProvider(create: (context) {
          final authBloc = getIt<AuthBloc>();
          if (AuthHelper.isLogin()) authBloc.add(const AuthEvent.checkAuthStatus());
          return authBloc;
        }),
        BlocProvider(create: (context) => RoleCubit()),
      ],
      child: BlocBuilder<LocalizationBloc, LocalizationState>(
        builder: (context, localeState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              // Determine theme mode based on state value
              final themeMode = themeState.when(dark: (value) => ThemeMode.dark, light: (value) => ThemeMode.light, system: (value) => ThemeMode.system);

              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                locale: localeState.locale,
                routerConfig: router,
                builder: (context, child) => BlocListener<SplashBloc, SplashState>(
                  listener: (context, state) {
                    state.maybeWhen(
                      loaded: (config) => openBlockedAppRoute(context, config),
                      orElse: () {},
                    );
                  },
                  child: FocusTraversalGroup(
                    policy: _focusTraversalPolicy,
                    child: RoleSwitcherOverlay(child: child ?? const SizedBox.shrink()),
                  ),
                ),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          );
        },
      ),
    );
  }
}
