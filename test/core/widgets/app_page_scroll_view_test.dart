import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _SplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _SplashBloc() : super(const SplashState.loading());
}

void main() {
  testWidgets('Page footer fills the width and reaches the bottom for short and long content', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 800), const Size(900, 700), const Size(1440, 700), const Size(1440, 1600)]) {
      tester.view.physicalSize = size;
      for (final language in ['en', 'bn', 'ar']) {
        for (final contentHeight in [100.0, 2400.0]) {
          await tester.pumpWidget(BlocProvider<SplashBloc>(
            create: (_) => _SplashBloc(),
            child: MaterialApp(
              theme: AppTheme.light,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
              home: Scaffold(body: AppPageScrollView(
                padding: const EdgeInsets.all(16),
                maxWidth: 600,
                children: [SizedBox(key: const ValueKey('content'), height: contentHeight)],
              )),
            ),
          ));
          await tester.pumpAndSettle();
          final footer = find.byType(AppFooter);
          expect(tester.getSize(find.byKey(const ValueKey('content'))).width, lessThanOrEqualTo(600));
          if (size.width == 320) {
            expect(footer, findsNothing);
          } else {
            expect(footer, findsOneWidget);
            expect(tester.getSize(footer).width, size.width);
            final position = Scrollable.of(tester.element(footer)).position;
            if (size.height == 1600 && contentHeight == 100) expect(position.maxScrollExtent, 0);
            position.jumpTo(position.maxScrollExtent);
            await tester.pumpAndSettle();
            expect(tester.getRect(footer).bottom, closeTo(size.height, 1));
          }
          expect(tester.takeException(), isNull, reason: '$size $language $contentHeight');
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
