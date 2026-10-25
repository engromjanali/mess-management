import 'package:mess_pilot/config/theme/custom_theme_colors.dart';
import 'package:mess_pilot/features/settings/domain/entities/theme_mode.dart';
import 'package:mess_pilot/config/util/app_constants.dart';

import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:mess_pilot/features/settings/presentation/screens/settings_screen.dart';
import 'package:mess_pilot/features/settings/presentation/widgets/language_selection_overlay.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Manual Mock ThemeBloc
class MockThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  ThemeEvent? lastEvent;

  MockThemeBloc() : super(const ThemeState.light()) {
    on<ThemeEvent>((event, emit) { lastEvent = event; });
  }
}

// Manual Mock LocalizationBloc
class MockLocalizationBloc extends Bloc<LocalizationEvent, LocalizationState>
    implements LocalizationBloc {
  MockLocalizationBloc()
      : super(LocalizationState.initial(const Locale('en'))) {
    on<LocalizationEvent>((event, emit) {});
  }
}

void main() {
  late MockThemeBloc mockThemeBloc;
  late MockLocalizationBloc mockLocalizationBloc;

  setUp(() {
    mockThemeBloc = MockThemeBloc();
    mockLocalizationBloc = MockLocalizationBloc();
  });

  tearDown(() {
    mockThemeBloc.close();
    mockLocalizationBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: mockThemeBloc),
        BlocProvider<LocalizationBloc>.value(value: mockLocalizationBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppConstants.languages.map((e) => Locale(e.code)).toList(),
        locale: const Locale('en'),
        theme: ThemeData(
          extensions: [
            CustomThemeColors.light(),
          ],
        ),
        home: const SettingsScreen(),
      ),
    );
  }

  testWidgets('SettingsScreen displays Language and Theme sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Check titles
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    
    // Check initial values (English is default, Light mode is default)
    expect(find.text('English'), findsOneWidget); 
    
    final local = AppLocalizations.of(tester.element(find.byType(SettingsScreen)));
    expect(find.text(local.uiLightMode), findsOneWidget);
    expect(find.text(local.uiSystemDefault), findsOneWidget);
  });

  testWidgets('Tapping Language tile opens overlay',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.widgetWithText(ListTile, 'Select Language'));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectionOverlay), findsOneWidget);
  });

  testWidgets('Selecting dark theme sends the requested mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.widgetWithText(ListTile, 'Dark Mode'));
    await tester.pump();
    expect(mockThemeBloc.lastEvent, const ThemeEvent.changeThemeMode(AppThemeMode.dark));
  });
}
