import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_entry_form.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Next moves product to price, then appends and focuses the next product', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: CostEntryForm(members: const [CostMemberEntity(id: '1', name: 'Member')], onSubmit: ({required personId, required date, required items}) {}))),
    ));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rice');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(find.descendant(of: fields.at(1), matching: find.byType(TextField))).focusNode!.hasFocus, isTrue);
    await tester.enterText(fields.at(1), '125.50');
    expect(fields, findsNWidgets(2));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(fields, findsNWidgets(4));
    expect(tester.widget<TextField>(find.descendant(of: fields.at(2), matching: find.byType(TextField))).focusNode!.hasFocus, isTrue);
    final price = tester.widget<TextFormField>(fields.at(1)).controller!;
    expect(price.text, '125.50');
    await tester.enterText(fields.at(1), '150');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(fields, findsNWidgets(4));
    expect(tester.widget<TextField>(find.descendant(of: fields.at(2), matching: find.byType(TextField))).focusNode!.hasFocus, isTrue);
    await tester.enterText(fields.at(3), '');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(fields, findsNWidgets(4));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
