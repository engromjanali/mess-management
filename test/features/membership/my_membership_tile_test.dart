import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/features/membership/domain/entities/membership_status_entity.dart';
import 'package:mess_pilot/features/membership/presentation/widgets/my_membership_tile.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Leadership-only season shows a not-joined indicator without overflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const membership = MembershipSummaryEntity(
      membershipId: null,
      seasonId: 7,
      messId: 3,
      messName: 'Green House with a long name',
      seasonName: 'Historical season with a long name',
      role: 'manager',
      isManager: true,
      isCurrent: true,
      canSwitch: true,
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: MyMembershipTile(membership: membership, busy: false, onSwitch: null),
            ),
          ),
        ),
      ),
    ));

    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
    expect(find.text('Leadership access only · Not joined'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
