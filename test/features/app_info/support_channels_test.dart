import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/widgets/support_channels_view.dart';
import 'package:clean_boilerplate/features/splash/data/models/config_model.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/support_channel_entity.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Old config still supplies email and matching channels do not duplicate it', () {
    final oldConfig = ConfigModel.fromJson({'support_email': 'help@example.com'}).toEntity();
    expect(oldConfig.availableSupportChannels.single.contactUri.toString(), 'mailto:help@example.com');
    final config = ConfigModel.fromJson({
      'support_email': 'help@example.com',
      'support_channels': [
        {'name': 'Email team', 'kind': 'email', 'destination': 'help@example.com', 'url': 'mailto:help@example.com', 'logo_url': 'https://example.com/logo.png'},
        {'name': 'WhatsApp', 'kind': 'whatsapp', 'destination': '+8801712345678', 'url': 'https://wa.me/8801712345678'},
      ],
    }).toEntity();
    expect(config.availableSupportChannels, hasLength(2));
    expect(config.supportChannels.first.logoUrl, 'https://example.com/logo.png');
  });

  test('Unsupported schemes and links containing credentials cannot launch', () {
    for (final url in ['javascript:alert(1)', 'file:///etc/passwd', 'https://user:password@example.com', 'tel:', 'not a url']) {
      expect(SupportChannelEntity(name: 'Unsafe', kind: 'other', destination: url, url: url).contactUri, isNull);
    }
  });

  test('Configured email replaces a different legacy email and keeps its logo', () {
    final config = ConfigModel.fromJson({
      'support_email': 'old@example.com',
      'support_channels': [
        {'name': 'Email team', 'kind': 'email', 'destination': 'new@example.com', 'url': 'mailto:new@example.com', 'logo_url': 'https://example.com/logo.png'},
      ],
    }).toEntity();
    expect(config.availableSupportChannels.single.destination, 'new@example.com');
    expect(config.availableSupportChannels.single.logoUrl, 'https://example.com/logo.png');
    final fallback = ConfigModel.fromJson({
      'support_email': 'old@example.com',
      'support_channels': [
        {'name': 'Telegram', 'kind': 'telegram', 'destination': '@team', 'url': 'https://t.me/team'},
      ],
    }).toEntity();
    expect(fallback.availableSupportChannels, hasLength(2));
    expect(fallback.availableSupportChannels.last.destination, 'old@example.com');
  });

  Widget content(List<SupportChannelEntity> channels, {String language = 'en', double textScale = 1}) => MaterialApp(
    theme: AppTheme.light,
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
    home: Scaffold(body: ListView(children: [SupportChannelsView(channels: channels)])),
  );

  testWidgets('Long support details fit mobile, desktop, large text and RTL', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final channels = [
      SupportChannelEntity(name: 'Support ${'long-name-' * 20}', kind: 'website', destination: 'https://example.com/${'long-path-' * 40}', url: 'https://example.com', logoUrl: 'https://example.com/missing.png'),
      const SupportChannelEntity(name: '', kind: 'email', destination: 'help@example.com', url: 'mailto:help@example.com'),
    ];
    for (final width in [320.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1000);
      for (final language in ['en', 'bn', 'ar']) {
        await tester.pumpWidget(content(channels, language: language, textScale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Contacts launch externally and a failed launch shows an error', (tester) async {
    const methodChannel = MethodChannel('plugins.flutter.io/url_launcher');
    final launches = <Map<dynamic, dynamic>>[];
    var succeeds = true;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'launch') launches.add(call.arguments as Map<dynamic, dynamic>);
      return succeeds;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, null));
    final channels = [
      const SupportChannelEntity(name: 'Email', kind: 'email', destination: 'help@example.com', url: 'mailto:help@example.com'),
      const SupportChannelEntity(name: 'Call', kind: 'phone', destination: '+8801712345678', url: 'tel:+8801712345678'),
      const SupportChannelEntity(name: 'WhatsApp', kind: 'whatsapp', destination: '+8801712345678', url: 'https://wa.me/8801712345678'),
    ];
    await tester.pumpWidget(content(channels));
    await tester.pumpAndSettle();
    for (final channel in channels) {
      await tester.tap(find.text(channel.name));
      await tester.pumpAndSettle();
    }
    expect(launches.map((arguments) => arguments['url']), channels.map((channel) => channel.url));
    expect(launches.every((arguments) => arguments['useWebView'] == false && arguments['useSafariVC'] == false), isTrue);
    succeeds = false;
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(find.text('Could not open this support channel. Please try again.'), findsOneWidget);
  });
}
