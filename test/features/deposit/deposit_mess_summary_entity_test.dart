import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_mess_summary_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 6, 1);
  const members = [DepositMemberEntity(id: '1', name: 'Romjan'), DepositMemberEntity(id: '2', name: 'Mehedi'), DepositMemberEntity(id: '3', name: 'Sakib')];
  final deposits = [
    DepositEntity(id: 'a', memberId: '1', memberName: 'Romjan', amount: 3000, date: date),
    DepositEntity(id: 'b', memberId: '1', memberName: 'Romjan', amount: -500, date: date),
    DepositEntity(id: 'c', memberId: '2', memberName: 'Mehedi', amount: 1000, date: date),
  ];

  test('totals credits, debits and net across the mess', () {
    final summary = DepositMessSummaryEntity.fromDeposits(deposits, members);
    expect(summary.totalCredit, 4000);
    expect(summary.totalDebit, 500);
    expect(summary.netBalance, 3500);
    expect(summary.entries, 3);
  });

  test('includes members without deposits and counts active ones', () {
    final summary = DepositMessSummaryEntity.fromDeposits(deposits, members);
    expect(summary.memberCount, 3);
    expect(summary.activeMembers, 2);
    expect(summary.averagePerMember, closeTo(3500 / 3, 0.001));
  });

  test('member balances split credit/debit and sort by net, highest first', () {
    final balances = DepositMessSummaryEntity.fromDeposits(deposits, members).memberBalances;
    expect(balances.map((b) => b.memberName), ['Romjan', 'Mehedi', 'Sakib']);
    expect(balances.first.credit, 3000);
    expect(balances.first.debit, 500);
    expect(balances.first.net, 2500);
    expect(balances.last.entries, 0);
  });

  test('empty mess yields zeroes without dividing by zero', () {
    final summary = DepositMessSummaryEntity.fromDeposits(const [], const []);
    expect(summary.netBalance, 0);
    expect(summary.averagePerMember, 0);
    expect(summary.memberBalances, isEmpty);
  });

  test("carries the manager's own totals — a manager is also a member", () {
    final mine = deposits.where((d) => d.memberId == '1').toList();
    final summary = DepositMessSummaryEntity.fromDeposits(deposits, members, myDeposits: mine);
    expect(summary.mine!.credit, 3000);
    expect(summary.mine!.debit, 500);
    expect(summary.mine!.net, 2500);
    expect(summary.mine!.entries, 2);
    expect(DepositMessSummaryEntity.fromDeposits(deposits, members).mine, isNull);
  });
}
