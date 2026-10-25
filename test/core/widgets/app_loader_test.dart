import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/widgets/app_loader.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {bool dark = false, bool reducedMotion = false}) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion, textScaler: const TextScaler.linear(3)), child: child!),
    home: Scaffold(body: child),
  );

  testWidgets('Logo loader fits tight spaces in both themes and disposes its ticker', (tester) async {
    for (final dark in [false, true]) {
      for (final size in [24.0, 96.0, 132.0]) {
        await tester.pumpWidget(host(Center(child: SizedBox.square(dimension: size, child: const AppLoader())), dark: dark));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Overlay blocks taps and releases the child when loading ends', (tester) async {
    var taps = 0;
    Widget content(bool loading) => host(AppLoadingOverlay(isLoading: loading, child: Center(child: TextButton(onPressed: () => taps++, child: const Text('Action')))));
    await tester.pumpWidget(content(true));
    await tester.tap(find.text('Action'), warnIfMissed: false);
    expect(taps, 0);
    await tester.pumpWidget(content(false));
    await tester.tap(find.text('Action'));
    expect(taps, 1);
    expect(find.byType(AppLoader), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion stops animation and overlay fits a narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(240, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const AppLoadingOverlay(isLoading: true, child: SizedBox.expand()), reducedMotion: true));
    await tester.pumpAndSettle();
    final rotation = tester.widget<RotationTransition>(find.descendant(of: find.byType(AppLoader), matching: find.byType(RotationTransition)));
    expect(rotation.turns.value, 0);
    expect(tester.takeException(), isNull);
  });
}
