import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/features/home/presentation/widgets/feedback_banner_card.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('FeedbackBannerCard renders message and navigates to feedback route', (tester) async {
    var navigated = false;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: FeedbackBannerCard(),
          ),
        ),
        GoRoute(
          path: AppRoutes.feedback,
          builder: (context, state) {
            navigated = true;
            return const Scaffold(body: Text('Feedback Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ));

    await tester.pumpAndSettle();
    expect(find.byType(FeedbackBannerCard), findsOneWidget);
    expect(find.text('Help Shape Mess Pilot!'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);

    await tester.tap(find.byType(FeedbackBannerCard));
    await tester.pumpAndSettle();

    expect(navigated, isTrue);
    expect(find.text('Feedback Screen'), findsOneWidget);
  });

  testWidgets('FeedbackBannerCard renders without overflow at 320px with textScaler 2.0', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in ['en', 'bn', 'ar']) {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: FeedbackBannerCard(),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Failed on locale $locale');
    }
  });
}
