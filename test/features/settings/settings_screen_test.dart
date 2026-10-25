import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:clean_boilerplate/features/settings/presentation/screens/settings_screen.dart';
import 'package:clean_boilerplate/features/settings/presentation/widgets/language_selection_overlay.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  _ThemeBloc() : super(const ThemeState.system());
}

class _LocaleBloc extends Bloc<LocalizationEvent, LocalizationState> implements LocalizationBloc {
  _LocaleBloc() : super(const LocalizationState.loaded(Locale('en')));
}

class _AuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _AuthBloc() : super(const AuthState.initial());

  @override
  Future<void> refreshProfile() async {}
}

class _SplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _SplashBloc() : super(const SplashState.loading());
}

void main() {
  testWidgets('Settings and language overlay fit narrow, large text and RTL layouts', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _AuthBloc();
    addTearDown(auth.close);
    final theme = _ThemeBloc();
    final locale = _LocaleBloc();
    addTearDown(theme.close);
    addTearDown(locale.close);
    for (final language in ['en', 'bn', 'ar']) {
      for (final size in [const Size(320, 800), const Size(1440, 600), const Size(1440, 1600)]) {
        final width = size.width;
        tester.view.physicalSize = size;
        await tester.pumpWidget(MultiBlocProvider(providers: [
          BlocProvider<SplashBloc>(create: (_) => _SplashBloc()),
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<ThemeBloc>.value(value: theme),
          BlocProvider<LocalizationBloc>.value(value: locale),
        ], child: MaterialApp(
          theme: AppTheme.light,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
          home: const SettingsScreen(),
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$language $width settings');
        if (width == 1440) {
          expect(tester.getSize(find.byType(AppFooter)).width, width);
          final position = Scrollable.of(tester.element(find.byType(AppFooter))).position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(tester.getRect(find.byType(AppFooter)).bottom, closeTo(size.height, 1));
          position.jumpTo(0);
          await tester.pumpAndSettle();
        }
        final local = AppLocalizations.of(tester.element(find.byType(SettingsScreen)));
        await tester.tap(find.text(local.selectLanguage));
        await tester.pumpAndSettle();
        expect(find.byType(LanguageSelectionOverlay), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(tester.takeException(), isNull, reason: '$language $width overlay');
        Navigator.of(tester.element(find.byType(LanguageSelectionOverlay))).pop();
        await tester.pumpAndSettle();
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
