import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/widgets/app_state_view.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {String language = 'en', bool dark = false, double scale = 1}) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
    home: Scaffold(body: child),
  );

  testWidgets('Error and empty states fit phone, desktop, RTL, large text and short screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(240, 320), const Size(320, 200), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      for (final dark in [false, true]) {
        for (final language in ['en', 'bn', 'ar']) {
          for (final scale in [1.0, 3.0]) {
            for (final child in [
              AppErrorState(error: 'No internet connection. Please check your network.', onRetry: () {}),
              AppErrorState(error: 'Something went wrong', onRetry: () {}),
              const AppEmptyState(title: 'No entries available yet', icon: Icons.inbox_outlined),
            ]) {
              await tester.pumpWidget(host(child, language: language, dark: dark, scale: scale));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: '$size $language dark=$dark scale=$scale');
            }
          }
        }
      }
    }
  });

  testWidgets('Error categories use localized titles and hide technical details', (tester) async {
    final local = await AppLocalizations.delegate.load(const Locale('bn'));
    for (final (error, title) in <(Object, String)>[
      (NoInternetException(message: 'internal network details'), local.stateOfflineTitle),
      (RequestTimeoutException(message: 'internal timeout details'), local.stateTimeoutTitle),
      (ServerException(message: 'internal server details', statusCode: 503), local.stateServiceTitle),
      (UnauthorizedException(message: 'internal auth details', statusCode: 403), local.stateAccessTitle),
      (UnauthorizedException(message: 'internal auth details'), local.stateSessionTitle),
      ('Authorization: Bearer secret-token', local.stateErrorTitle),
    ]) {
      await tester.pumpWidget(host(AppErrorState(error: error, onRetry: () {}), language: 'bn'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining('internal'), findsNothing);
      expect(find.textContaining('secret-token'), findsNothing);
    }
  });

  testWidgets('Retry and secondary actions remain reachable in a short viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retries = 0;
    var secondary = 0;
    await tester.pumpWidget(host(AppErrorState(error: 'Something went wrong', onRetry: () => retries++, secondaryAction: TextButton(onPressed: () => secondary++, child: const Text('Join mess'))), scale: 3));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    expect(retries, 1);
    await tester.ensureVisible(find.text('Join mess'));
    await tester.tap(find.text('Join mess'));
    expect(secondary, 1);
    expect(tester.takeException(), isNull);
  });
}
