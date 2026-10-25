import 'package:clean_boilerplate/config/theme/app_theme.dart';
import 'package:clean_boilerplate/core/widgets/app_user_avatar.dart';
import 'package:clean_boilerplate/features/cost/data/models/cost_model.dart';
import 'package:clean_boilerplate/features/meal/data/models/meal_admin_model.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_mess_summary_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(body: Center(child: child)));

  testWidgets('Avatar uses initials or a person icon instead of numbers without overflow', (tester) async {
    for (final radius in [14.0, 18.0, 40.0]) {
      await tester.pumpWidget(host(AppUserAvatar(name: 'Romjan Ali', radius: radius)));
      expect(find.text('RA'), findsOneWidget);
      expect(tester.getSize(find.byType(AppUserAvatar)), Size.square(radius * 2));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(host(const AppUserAvatar(name: '123')));
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    await tester.pumpWidget(host(const AppUserAvatar(name: '', photoUrl: 'javascript:invalid')));
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Broken profile photos fall back to initials', (tester) async {
    await tester.pumpWidget(host(const AppUserAvatar(name: 'Romjan Ali', photoUrl: 'https://example.test/photo.png')));
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('RA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Photo URLs survive model conversion and deposit aggregation', () {
    const photo = 'https://example.test/photo.png';
    final cost = CostModel(id: '1', personId: '2', personName: 'Member', date: DateTime(2026), items: const [], personPhotoUrl: photo);
    expect(cost.copyWith().toEntity().personPhotoUrl, photo);
    expect(MealMemberModel.fromJson({'id': 2, 'name': 'Member', 'photo': photo}).toEntity().photoUrl, photo);
    final summary = DepositMessSummaryEntity.fromDeposits([DepositEntity(id: '1', memberId: '2', memberName: 'Member', amount: 100, date: DateTime(2026))], const [DepositMemberEntity(id: '2', name: 'Member', photoUrl: photo)]);
    expect(summary.memberBalances.single.photoUrl, photo);
    expect(summary.memberBalances.single.credit, 100);
  });
}
