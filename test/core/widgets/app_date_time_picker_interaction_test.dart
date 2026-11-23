import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/core/widgets/app_date_time_picker_sheet.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

void main() {
  Future<DateTime?> openAndInteract(
    WidgetTester tester, {
    required Future<void> Function(WidgetTester tester) interact,
    Size size = const Size(360, 740),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DateTime? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await AppDateTimePickerSheet.show(
                  context,
                  initial: DateTime(2030, 7, 16, 18, 30),
                  minDate: DateTime(2030, 1, 1),
                  maxDate: DateTime(2030, 12, 31),
                  timeLabel: 'End time',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await interact(tester);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('touch drag on hour drum changes the hour', (tester) async {
    final result = await openAndInteract(tester, interact: (tester) async {
      await tester.drag(find.byType(ListWheelScrollView).first, const Offset(0, -60));
      await tester.pumpAndSettle();
    });
    // 6 PM + 2 steps (60px / 30px itemExtent) = 8 PM
    expect(result, DateTime(2030, 7, 16, 20, 30), reason: 'drag on drum should change hour');
  });

  testWidgets('touch drag on hour drum works in desktop dialog layout', (tester) async {
    final result = await openAndInteract(tester, size: const Size(1400, 900), interact: (tester) async {
      await tester.drag(find.byType(ListWheelScrollView).first, const Offset(0, -60));
      await tester.pumpAndSettle();
    });
    expect(result, isNot(DateTime(2030, 7, 16, 18, 30)), reason: 'drag on drum should change hour in dialog layout');
  });

  testWidgets('mouse wheel on minute drum works in desktop dialog layout', (tester) async {
    final pointer = TestPointer(2, PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);

    final result = await openAndInteract(tester, size: const Size(1400, 900), interact: (tester) async {
      final minuteWheel = find.byType(ListWheelScrollView).at(1);
      pointer.hover(tester.getCenter(minuteWheel));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
      await tester.pumpAndSettle();
    });
    expect(result, isNot(DateTime(2030, 7, 16, 18, 30)), reason: 'mouse wheel on drum should change minute in dialog layout');
    expect(result?.hour, 18);
  });

  testWidgets('mouse wheel on minute drum changes the minute', (tester) async {
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);

    final result = await openAndInteract(tester, interact: (tester) async {
      final minuteWheel = find.byType(ListWheelScrollView).at(1);
      pointer.hover(tester.getCenter(minuteWheel));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
      await tester.pumpAndSettle();
    });
    expect(result, isNot(DateTime(2030, 7, 16, 18, 30)), reason: 'mouse wheel on drum should change minute');
    expect(result?.hour, 18);
  });
}
