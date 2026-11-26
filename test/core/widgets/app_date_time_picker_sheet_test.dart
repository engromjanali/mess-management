import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/widgets/app_date_time_picker_sheet.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

void main() {
  Widget host({String language = 'en', double textScale = 1, required void Function(BuildContext) onOpen}) => MaterialApp(
        theme: AppTheme.light,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(onPressed: () => onOpen(context), child: const Text('open')),
            ),
          ),
        ),
      );

  Future<void> openSheet(
    WidgetTester tester, {
    String language = 'en',
    double textScale = 1,
    Size size = const Size(360, 740),
    DateTime? initial,
    void Function(DateTime?)? onResult,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(
      language: language,
      textScale: textScale,
      onOpen: (context) async {
        final result = await AppDateTimePickerSheet.show(
          context,
          initial: initial ?? DateTime(2030, 7, 16, 18, 30),
          minDate: DateTime(2030, 1, 1),
          maxDate: DateTime(2030, 12, 31),
          timeLabel: 'End time',
        );
        onResult?.call(result);
      },
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders calendar and time drums without overflow', (tester) async {
    await openSheet(tester);
    expect(find.text('Select Date & Time'), findsOneWidget);
    expect(find.text('End time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow in Bangla with larger text', (tester) async {
    await openSheet(tester, language: 'bn', textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a day and saving returns the composed date and time', (tester) async {
    DateTime? result;
    await openSheet(tester, onResult: (value) => result = value);

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2030, 7, 20, 18, 30));
  });

  testWidgets('cancel dismisses without a result', (tester) async {
    var called = false;
    await openSheet(tester, onResult: (value) {
      called = true;
      expect(value, isNull);
    });

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(tester.takeException(), isNull);
  });
}
