import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/features/home/presentation/widgets/pinned_section_header.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('SliverMainAxisGroup unpins previous header as next section arrives', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Container(height: 150, color: Colors.blue),
              ),
              SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedSectionHeader(title: 'Section 1', icon: Icons.groups_rounded),
                  ),
                  SliverToBoxAdapter(
                    child: Container(height: 500, color: Colors.grey.shade200),
                  ),
                ],
              ),
              SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedSectionHeader(title: 'Section 2', icon: Icons.person_rounded),
                  ),
                  SliverToBoxAdapter(
                    child: Container(height: 500, color: Colors.grey.shade300),
                  ),
                ],
              ),
              SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedSectionHeader(title: 'Section 3', icon: Icons.bar_chart_rounded),
                  ),
                  SliverToBoxAdapter(
                    child: Container(height: 500, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // At top: Section 1 header is below the blue box (y = 150)
    final sec1TopInitial = tester.getTopLeft(find.text('Section 1')).dy;
    expect(sec1TopInitial, greaterThanOrEqualTo(150.0));

    // Scroll down 200px: Blue box scrolled off, Section 1 header is pinned at y = 0
    scrollController.jumpTo(200);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Section 1')).dy, lessThanOrEqualTo(50.0));

    // Scroll down 750px (into Section 2): Section 1 header has been pushed offscreen!
    scrollController.jumpTo(750);
    await tester.pumpAndSettle();

    // Section 1 is offscreen (findNothing or y < 0)
    final sec1Found = find.text('Section 1');
    if (sec1Found.evaluate().isNotEmpty) {
      expect(tester.getBottomRight(sec1Found).dy, lessThanOrEqualTo(0.0));
    }

    // Section 2 header is now pinned at top!
    expect(find.text('Section 2'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Section 2')).dy, lessThanOrEqualTo(50.0));
  });
}
