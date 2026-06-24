import 'package:equatable/equatable.dart';

/// Whether a fund entry moves money **in** (credit) or **out** (debit).
///
/// Funds can be positive or negative — a positive amount is a credit (money
/// added to the mess fund), a negative amount is a debit (money taken out /
/// an adjustment).
enum FundType {
  credit,
  debit;

  String get label => this == FundType.credit ? 'Credit' : 'Debit';
}

/// A single mess fund record.
///
/// Unlike a deposit, a fund is not tied to a member and carries no note —
/// it is a shared money-in / money-out entry. [amount] keeps its sign:
/// positive → [FundType.credit], negative → [FundType.debit].
class FundEntity extends Equatable {
  final String id;
  final double amount;
  final DateTime date;

  const FundEntity({
    required this.id,
    required this.amount,
    required this.date,
  });

  /// Credit when zero or positive, debit when negative.
  FundType get type => amount < 0 ? FundType.debit : FundType.credit;

  bool get isCredit => type == FundType.credit;

  bool get isDebit => type == FundType.debit;

  /// Sign-less magnitude, for display next to a debit/credit badge.
  double get absoluteAmount => amount.abs();

  @override
  List<Object?> get props => [id, amount, date];
}

/// Aggregate helpers over a list of funds (used for summary cards).
extension FundListX on List<FundEntity> {
  /// Sum of all credit (positive) amounts.
  double get totalCredit =>
      where((f) => f.isCredit).fold<double>(0, (sum, f) => sum + f.amount);

  /// Sum of all debit (negative) amounts, returned as a positive magnitude.
  double get totalDebit => where((f) => f.isDebit)
      .fold<double>(0, (sum, f) => sum + f.absoluteAmount);

  /// Net balance — credits minus debits (signed).
  double get net => fold<double>(0, (sum, f) => sum + f.amount);
}
