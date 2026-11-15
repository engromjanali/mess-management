import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/widgets/app_dialog.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('AppDialog fits narrow screens with large text in every locale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in ['en', 'bn', 'ar']) {
      var confirmed = false;
      await tester.pumpWidget(MaterialApp(
        key: ValueKey(locale),
        theme: AppTheme.light,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAppConfirmDialog(
                  context,
                  title: 'A long dialog title that wraps onto more than one line',
                  message: 'A longer explanation that also wraps and keeps the dialog content readable on the narrowest phone.',
                  confirmLabel: 'Confirm action',
                  destructive: true,
                ).then((value) => confirmed = value),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);
      expect(tester.takeException(), isNull, reason: locale);

      await tester.tap(find.text('Confirm action'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue, reason: locale);
    }
  });

  testWidgets('AppDialog close button dismisses without confirming', (tester) async {
    var confirmed = true;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAppConfirmDialog(context, title: 'Delete item', message: 'This cannot be undone.', confirmLabel: 'Delete', destructive: true).then((value) => confirmed = value),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(MaterialLocalizations.of(tester.element(find.byType(AppDialog))).closeButtonTooltip));
    await tester.pumpAndSettle();

    expect(find.byType(AppDialog), findsNothing);
    expect(confirmed, isFalse);
  });
}
