import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/widgets/app_snackbar_content.dart';
import 'package:clean_boilerplate/core/widgets/app_desktop_toast.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('All snackbar states fit light, dark, mobile, desktop, RTL and a keyboard', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 800.0, 1200.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 800);
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        for (final language in ['en', 'bn', 'ar']) {
          for (final status in SnackBarStatus.values) {
            late BuildContext screenContext;
            await tester.pumpWidget(MaterialApp(
              theme: theme,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2), viewInsets: const EdgeInsets.only(bottom: 300)), child: child!),
              home: Scaffold(body: Builder(builder: (context) {
                screenContext = context;
                return const SizedBox.expand();
              })),
            ));
            final message = '${AppLocalizations.of(screenContext).actionNotAllowed} ${'long-message-' * 100}';
            switch (status) {
              case SnackBarStatus.error: screenContext.showErrorSnackBar(message);
              case SnackBarStatus.success: screenContext.showSuccessSnackBar(message);
              case SnackBarStatus.info: screenContext.showInfoSnackBar(message);
              case SnackBarStatus.alert: screenContext.showAlertSnackBar(message);
            }
            await tester.pumpAndSettle();
            expect(find.byType(AppSnackbarContent), findsOneWidget);
            expect(tester.getSize(find.byType(AppSnackbarContent)).width, lessThanOrEqualTo(560));
            final rect = tester.getRect(find.byType(AppSnackbarContent));
            if (width > 1260) {
              expect(find.byType(AppDesktopToast), findsOneWidget);
              expect(rect.top, closeTo(30, 1));
              expect(rect.right, closeTo(width - 30, 1));
            } else {
              expect(find.byType(SnackBar), findsOneWidget);
              expect(rect.center.dx, closeTo(width / 2, 1));
              expect(rect.bottom, lessThanOrEqualTo(500));
              expect(rect.top, greaterThan(200));
            }
            expect(tester.takeException(), isNull);
            await tester.tap(find.byTooltip(MaterialLocalizations.of(screenContext).closeButtonTooltip));
            await tester.pumpAndSettle();
            expect(find.byType(SnackBar), findsNothing);
            expect(find.byType(AppDesktopToast), findsNothing);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      }
    }
  });

  testWidgets('A new error replaces the old snackbar and hides private details', (tester) async {
    late BuildContext screenContext;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) {
        screenContext = context;
        return const SizedBox.expand();
      })),
    ));
    screenContext.showErrorSnackBar('First error');
    await tester.pumpAndSettle();
    screenContext.showErrorSnackBar(const ServerFailure(message: 'PRIVATE_SERVER_TRACE', statusCode: 500));
    await tester.pumpAndSettle();
    expect(find.text('First error'), findsNothing);
    expect(find.text('PRIVATE_SERVER_TRACE'), findsNothing);
    expect(find.text(AppLocalizations.of(screenContext).serviceUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Desktop toast replaces previous messages and expires automatically', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late BuildContext screenContext;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) {
        screenContext = context;
        return const SizedBox.expand();
      })),
    ));
    screenContext.showInfoSnackBar('First message');
    await tester.pump();
    screenContext.showSuccessSnackBar('Latest message', duration: const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('First message'), findsNothing);
    expect(find.text('Latest message'), findsOneWidget);
    tester.view.physicalSize = const Size(800, 900);
    await tester.pump();
    final resized = tester.getRect(find.byType(AppSnackbarContent));
    expect(resized.center.dx, closeTo(400, 1));
    expect(resized.bottom, closeTo(870, 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(AppDesktopToast), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
