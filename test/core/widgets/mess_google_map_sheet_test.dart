import 'package:mess_pilot/core/widgets/mess_google_map_sheet.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

class _MapPlatform extends MethodChannelGoogleMapsFlutter {
  final created = <int>{};
  final disposals = <int, int>{};

  @override
  Future<void> init(int mapId) async {
    ensureChannelInitialized(mapId);
  }

  @override
  void dispose({required int mapId}) {
    disposals.update(mapId, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  Widget buildViewWithConfiguration(int creationId, PlatformViewCreatedCallback onPlatformViewCreated, {required MapWidgetConfiguration widgetConfiguration, MapObjects mapObjects = const MapObjects(), MapConfiguration mapConfiguration = const MapConfiguration()}) {
    if (created.add(creationId)) onPlatformViewCreated(creationId);
    return const SizedBox.expand();
  }
}

void main() {
  testWidgets('Repeated map dialogs release each controller exactly once', (tester) async {
    final previousPlatform = GoogleMapsFlutterPlatform.instance;
    final platform = _MapPlatform();
    GoogleMapsFlutterPlatform.instance = platform;
    addTearDown(() => GoogleMapsFlutterPlatform.instance = previousPlatform);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => showMessGoogleMap(context: context, latitude: 23.81, longitude: 90.41), child: const Text('Open map')))),
    ));
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('Open map'));
      await tester.pumpAndSettle();
      expect(find.byType(MessGoogleMapSheet), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(platform.created.length, 3);
    expect(platform.disposals.values, everyElement(1));
    expect(platform.disposals.length, 3);
  });
}
