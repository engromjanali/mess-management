import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/widgets/app_snackbar_content.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/edit_mess_screen.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget home, {String language = 'en', double textScale = 1}) => MaterialApp(
    theme: AppTheme.light,
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
    home: home,
  );

  testWidgets('Validation errors appear beside fields and clear when edited', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.method == 'PATCH') {
        handler.reject(DioException(requestOptions: options, type: DioExceptionType.badResponse, response: Response(requestOptions: options, statusCode: 400, data: {'email': ['Enter a valid email address.']})));
      } else {
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
          'id': 1, 'name': 'Green House', 'email': 'house@example.com', 'phone': '', 'address': '',
          'season': {'id': 1, 'name': 'Season', 'start_date': '2026-10-01'},
          'stats': <String, dynamic>{}, 'joined_at': '2026-10-01',
        }));
      }
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() => getIt.unregister<ApiClient>());
    await tester.pumpWidget(app(const EditMessScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Please correct the highlighted fields and save again.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'newhouse@example.com');
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fields validate locally and phone uses the selected country prefix', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 1100);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final dio = Dio();
    addTearDown(dio.close);
    Map<String, dynamic>? saved;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.method == 'PATCH') {
        saved = Map<String, dynamic>.from(options.data as Map);
        handler.resolve(Response(requestOptions: options, statusCode: 200));
      } else {
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
          'id': 1, 'name': 'Green House', 'email': '', 'phone': '+8801712345678', 'address': '',
          'season': {'id': 1, 'name': 'Season', 'start_date': '2026-10-01'},
          'stats': <String, dynamic>{}, 'joined_at': '2026-10-01',
        }));
      }
    }));
    getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
    addTearDown(() => getIt.unregister<ApiClient>());
    await tester.pumpWidget(app(const EditMessScreen(), textScale: 2));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(find.text('+880'), findsOneWidget);
    expect((tester.widget<TextFormField>(fields.at(3)).controller!).text, '1712345678');
    await tester.enterText(fields.at(0), '');
    await tester.enterText(fields.at(2), 'invalid email');
    await tester.enterText(fields.at(3), '12');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(find.text('Mess name is required.'), findsOneWidget);
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Please enter a valid phone number'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(fields.at(0), 'Green House');
    await tester.enterText(fields.at(3), '1812345678');
    for (final email in ['a..b@example.com', 'user@localhost', 'user@example..com', 'user @example.com']) {
      await tester.enterText(fields.at(2), email);
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(saved, isNull);
    }
    await tester.enterText(fields.at(2), 'house+manager@example.com');
    await tester.enterText(fields.at(3), '0000000000');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(find.text('Please enter a valid phone number'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(fields.at(3), '1812345678');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saved?['phone'], '+8801812345678');
    expect(saved?['email'], 'house+manager@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Error snackbars fit mobile, desktop, large text and RTL', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1000);
      for (final language in ['en', 'bn', 'ar']) {
        await tester.pumpWidget(app(Scaffold(body: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.error_outline),
          onPressed: () => context.showErrorSnackBar(AppLocalizations.of(context).messDetailsPermissionDenied),
        ))), language: language, textScale: 2));
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();
        expect(find.byType(AppSnackbarContent), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('Load failures use friendly messages without exposing server details', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    for (final scenario in [
      (DioExceptionType.badResponse, 500, 'Could not load mess details. Please try again.'),
      (DioExceptionType.badResponse, 403, 'Only the manager or acting manager can edit mess details.'),
      (DioExceptionType.badResponse, 401, 'Your session has expired. Please sign in again.'),
      (DioExceptionType.connectionError, null, 'Cannot connect. Check your internet connection and try again.'),
      (DioExceptionType.receiveTimeout, null, 'The request took too long. Please try again.'),
    ]) {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) => handler.reject(DioException(
        requestOptions: options,
        type: scenario.$1,
        response: scenario.$2 == null ? null : Response(requestOptions: options, statusCode: scenario.$2, data: {'detail': 'PRIVATE_SERVER_TRACE'}),
      ))));
      getIt.registerSingleton<ApiClient>(ApiClient(dio: dio, sharedPreferences: preferences));
      await tester.pumpWidget(app(const EditMessScreen()));
      await tester.pumpAndSettle();
      expect(find.text(scenario.$3), findsOneWidget);
      expect(find.textContaining('PRIVATE_SERVER_TRACE'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await getIt.unregister<ApiClient>();
      dio.close();
    }
  });
}
