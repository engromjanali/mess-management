import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';
import 'package:clean_boilerplate/features/notice/presentation/screens/notice_details_screen.dart';
import 'package:clean_boilerplate/features/notice/presentation/widgets/notice_card.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';

void main() {
  testWidgets('Notice preview opens full details and fits large text on a phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notice = NoticeEntity(id: '1', title: 'Long notice title ' * 12, description: 'Full notice content ' * 80, createdAt: DateTime(2026, 10, 22), pinned: true);
    final routes = GoRouter(initialLocation: AppRoutes.notices, routes: [
      GoRoute(path: AppRoutes.notices, builder: (context, state) => Scaffold(body: SingleChildScrollView(child: NoticeCard(
        notice: notice,
        showActions: true,
        onTap: () => context.go(AppRoutes.getNoticeDetailsRoute(notice.id), extra: notice),
      ))), routes: [
      GoRoute(path: ':id', builder: (context, state) => NoticeDetailsScreen(noticeId: state.pathParameters['id'], notice: state.extra as NoticeEntity)),
      ]),
    ]);
    addTearDown(routes.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: routes,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(notice.title)).maxLines, 2);
    expect(tester.widget<Text>(find.text(notice.description)).maxLines, 3);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(notice.title));
    await tester.pumpAndSettle();
    expect(find.byType(NoticeDetailsScreen), findsOneWidget);
    expect(routes.routeInformationProvider.value.uri.path, '/notices/1');
    expect(tester.widget<Text>(find.text(notice.description)).maxLines, isNull);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(NoticeDetailsScreen), findsNothing);
  });
}
