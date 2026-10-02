import 'package:equatable/equatable.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';

/// One member's deposit totals within the mess.
class DepositMemberBalanceEntity extends Equatable {
  final String memberId;
  final String memberName;
  final double credit;
  final double debit;
  final int entries;

  const DepositMemberBalanceEntity({required this.memberId, required this.memberName, required this.credit, required this.debit, required this.entries});

  /// Credits minus debits (signed).
  double get net => credit - debit;

  @override
  List<Object?> get props => [memberId, memberName, credit, debit, entries];
}

/// Mess-wide deposit totals (admin view), independent of the list filter.
class DepositMessSummaryEntity extends Equatable {
  final double totalCredit;
  final double totalDebit;
  final int entries;

  /// Every member of the mess, including those without deposits, sorted by net (highest first).
  final List<DepositMemberBalanceEntity> memberBalances;

  /// The signed-in manager's own totals — a manager is also a member.
  final DepositMemberBalanceEntity? mine;

  const DepositMessSummaryEntity({required this.totalCredit, required this.totalDebit, required this.entries, required this.memberBalances, this.mine});

  /// Builds the summary from every deposit of the season plus the member list,
  /// and the manager's own balance from [myDeposits] when given.
  factory DepositMessSummaryEntity.fromDeposits(List<DepositEntity> deposits, List<DepositMemberEntity> members, {List<DepositEntity>? myDeposits}) {
    final byMember = <String, DepositMemberBalanceEntity>{
      for (final m in members) m.id: DepositMemberBalanceEntity(memberId: m.id, memberName: m.name, credit: 0, debit: 0, entries: 0),
    };
    for (final d in deposits) {
      final current = byMember[d.memberId] ?? DepositMemberBalanceEntity(memberId: d.memberId, memberName: d.memberName, credit: 0, debit: 0, entries: 0);
      byMember[d.memberId] = DepositMemberBalanceEntity(
        memberId: current.memberId,
        memberName: current.memberName,
        credit: current.credit + (d.isCredit ? d.amount : 0),
        debit: current.debit + (d.isDebit ? d.absoluteAmount : 0),
        entries: current.entries + 1,
      );
    }
    final balances = byMember.values.toList()..sort((a, b) => b.net.compareTo(a.net));
    final mine = myDeposits == null
        ? null
        : DepositMemberBalanceEntity(
            memberId: myDeposits.isEmpty ? '' : myDeposits.first.memberId,
            memberName: myDeposits.isEmpty ? '' : myDeposits.first.memberName,
            credit: myDeposits.totalCredit,
            debit: myDeposits.totalDebit,
            entries: myDeposits.length,
          );
    return DepositMessSummaryEntity(totalCredit: deposits.totalCredit, totalDebit: deposits.totalDebit, entries: deposits.length, memberBalances: balances, mine: mine);
  }

  /// Credits minus debits (signed).
  double get netBalance => totalCredit - totalDebit;

  int get memberCount => memberBalances.length;

  /// Members with at least one deposit entry.
  int get activeMembers => memberBalances.where((b) => b.entries > 0).length;

  /// Net balance shared evenly across members.
  double get averagePerMember => memberCount == 0 ? 0 : netBalance / memberCount;

  @override
  List<Object?> get props => [totalCredit, totalDebit, entries, memberBalances, mine];
}
