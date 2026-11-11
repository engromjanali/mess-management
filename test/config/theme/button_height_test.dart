import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/config/theme/light_theme_data.dart';
import 'package:mess_pilot/config/util/dimensions.dart';

void main() {
  testWidgets('Every button type is 40px tall', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightThemeData,
        home: Scaffold(
          body: Column(
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              TextButton(onPressed: () {}, child: const Text('Text')),
            ],
          ),
        ),
      ),
    );

    for (final type in [ElevatedButton, OutlinedButton, FilledButton, TextButton]) {
      expect(tester.getSize(find.byType(type)).height, Dimensions.buttonHeight);
    }
  });
}
