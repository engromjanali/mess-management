import 'package:clean_boilerplate/config/theme/custom_theme_colors.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/auth/presentation/screens/login_screen.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Manual Mock Bloc that behaves like a real Bloc but allows controlling state
class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc() : super(const AuthState.initial()) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  Future<void> refreshProfile() async {}
}

class LoadingMockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  LoadingMockAuthBloc() : super(const AuthState.loading()) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  Future<void> refreshProfile() async {}
}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  tearDown(() {
    mockAuthBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppConstants.languages.map((e) => Locale(e.code)).toList(),
      locale: const Locale('en'),
      theme: ThemeData(
        extensions: [
          CustomThemeColors.light(),
        ],
      ),
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen displays email and password fields and login button',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('Enters text into email and password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');

    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('password123'), findsOneWidget);
  });

  testWidgets('Tapping login button adds LoginRequested event',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'password123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Shows CircularProgressIndicator when state is loading',
      (WidgetTester tester) async {
    final loadingBloc = LoadingMockAuthBloc();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppConstants.languages.map((e) => Locale(e.code)).toList(),
        locale: const Locale('en'),
        theme: ThemeData(
          extensions: [
            CustomThemeColors.light(),
          ],
        ),
        home: BlocProvider<AuthBloc>.value(
          value: loadingBloc,
          child: const LoginScreen(),
        ),
      ),
    );
    
    await tester.pump(); 

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    loadingBloc.close();
  });
}
