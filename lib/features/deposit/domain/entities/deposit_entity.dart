import 'package:equatable/equatable.dart';

/// Whether a deposit moves money **in** (credit) or **out** (debit).
///
/// Deposits can be positive or negative — a positive amount is a credit
/// (money added to the mess account), a negative amount is a debit (money
/// taken out / an adjustment).
enum DepositType {
  credit,
  debit;

  String get label => this == DepositType.credit ? 'Credit' : 'Debit';
}

/// A member that can have deposits recorded against them.
class DepositMemberEntity extends Equatable {
  final String id;
  final String name;

  const DepositMemberEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// A single deposit record for one member.
///
/// [amount] keeps its sign: positive → [DepositType.credit],
/// negative → [DepositType.debit].
class DepositEntity extends Equatable {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final DateTime date;
  final String? note;

  const DepositEntity({required this.id, required this.memberId, required this.memberName, required this.amount, required this.date, this.note});

  /// Credit when zero or positive, debit when negative.
  DepositType get type => amount < 0 ? DepositType.debit : DepositType.credit;

  bool get isCredit => type == DepositType.credit;

  bool get isDebit => type == DepositType.debit;

  /// Sign-less magnitude, for display next to a debit/credit badge.
  double get absoluteAmount => amount.abs();

  @override
  List<Object?> get props => [id, memberId, memberName, amount, date, note];
}

/// Aggregate helpers over a list of deposits (used for summary cards).
extension DepositListX on List<DepositEntity> {
  /// Sum of all credit (positive) amounts.
  double get totalCredit => where((d) => d.isCredit).fold<double>(0, (sum, d) => sum + d.amount);

  /// Sum of all debit (negative) amounts, returned as a positive magnitude.
  double get totalDebit => where((d) => d.isDebit).fold<double>(0, (sum, d) => sum + d.absoluteAmount);

  /// Net balance — credits minus debits (signed).
  double get net => fold<double>(0, (sum, d) => sum + d.amount);
}
