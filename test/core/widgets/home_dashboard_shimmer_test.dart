import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/widgets/app_shimmer.dart';
import 'package:mess_pilot/features/home/presentation/widgets/home_dashboard_shimmer.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home shimmer fits phone, tablet and desktop and disposes its animation', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [240.0, 320.0, 850.0, 851.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 400);
      for (final dark in [false, true]) {
        await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeDashboardShimmer()),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(AppShimmer), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion keeps a static skeleton', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
      home: const Scaffold(body: HomeDashboardShimmer()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(AppShimmer), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
