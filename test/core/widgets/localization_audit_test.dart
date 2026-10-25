import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_entry_form.dart';
import 'package:clean_boilerplate/features/fund/presentation/widgets/fund_formatters.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
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

  test('Date labels follow the explicitly selected locale', () async {
    for (final language in ['en', 'bn', 'ar']) {
      await AppLocalizations.delegate.load(Locale(language));
    }
    final date = DateTime(2026, 7, 1);
    expect(FundFormatters.date(date, locale: 'bn'), contains('জুল'));
    expect(FundFormatters.date(date, locale: 'ar'), contains('يوليو'));
  });
}
