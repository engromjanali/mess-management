import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/helpers/auth_helper.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/role/role_switcher_fab.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  // Configure dependency injection
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
                builder: (context, child) => RoleSwitcherOverlay(child: child ?? const SizedBox.shrink()),
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
