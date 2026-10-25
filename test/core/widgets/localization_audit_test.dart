import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/features/cost/domain/entities/cost_entity.dart';
import 'package:mess_pilot/features/cost/presentation/widgets/cost_entry_form.dart';
import 'package:mess_pilot/features/cost/presentation/widgets/cost_formatters.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_formatters.dart';
import 'package:mess_pilot/features/fund/presentation/widgets/fund_formatters.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:mess_pilot/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:mess_pilot/features/notice/presentation/widgets/notice_formatters.dart';
import 'package:mess_pilot/features/season/presentation/widgets/season_formatters.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuditSplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _AuditSplashBloc() : super(const SplashState.loading());
}

void main() {
  testWidgets('Localized cost form and footer fit narrow, desktop, large text and RTL layouts', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final splash = _AuditSplashBloc();
    addTearDown(splash.close);
    for (final language in ['en', 'bn', 'ar']) {
      for (final width in [320.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 1000);
        await tester.pumpWidget(BlocProvider<SplashBloc>.value(value: splash, child: MaterialApp(
          theme: AppTheme.light,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
          home: Scaffold(body: SingleChildScrollView(child: Column(children: [
            CostEntryForm(members: const [CostMemberEntity(id: '1', name: 'Member')], onSubmit: ({required personId, required date, required items}) {}),
            const AppFooter(),
          ]))),
        )));
        await tester.pumpAndSettle();
        final local = AppLocalizations.of(tester.element(find.byType(CostEntryForm)));
        expect(find.text(local.products), findsWidgets);
        expect(find.text(local.uiGetTheApp), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$language $width');
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Numbers and dates stay English with Latin digits in every app locale', () async {
    for (final language in ['en', 'bn', 'ar']) {
      await AppLocalizations.delegate.load(Locale(language));
      final date = DateTime(2026, 7, 1, 9, 5);
      expect(FundFormatters.date(date), '01 Jul 2026');
      expect(FundFormatters.taka(1234.5), '৳1,234.5');
      expect(DepositFormatters.date(date), '01 Jul 2026');
      expect(CostFormatters.date(date), '01/07/2026');
      expect(CostFormatters.time(date), '9:05 AM');
      expect(MealFormatters.dayLabel(date), 'Wed, 01 Jul');
      expect(NoticeFormatters.time(date), '9:05 AM · 01 Jul 2026');
      expect(DashboardFormatters.noticeTime(date), '9:05 AM · 01 Jul 2026');
      expect(SeasonFormatters.date(date), '1 Jul 2026');
    }
  });
}
