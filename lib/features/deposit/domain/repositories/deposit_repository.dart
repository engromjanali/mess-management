import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';

/// Deposit repository contract (abstraction in the domain layer).
abstract class DepositRepository {
  /// The roster of members a deposit can be recorded for.
  ResultFuture<List<DepositMemberEntity>> getMembers();

  /// Every deposit across all members and dates (newest first).
  ResultFuture<List<DepositEntity>> getAllDeposits();

  /// All deposits for a single member (newest first).
  ResultFuture<List<DepositEntity>> getMemberDeposits(String memberId);

  /// Every member's deposits on a single [date] (newest first).
  ResultFuture<List<DepositEntity>> getDepositsByDate(DateTime date);

  /// Every member's deposits within an inclusive [start]–[end] range.
  ResultFuture<List<DepositEntity>> getDepositsInRange(DateTime start, DateTime end);

  /// The signed-in user's own deposits only (newest first).
  ResultFuture<List<DepositEntity>> getMyDeposits();

  /// Records a deposit for **one** member at a time.
  ///
  /// [amount] keeps its sign — positive for a credit, negative for a debit.
  ResultFuture<DepositEntity> addDeposit({required String memberId, required double amount, required DateTime date, String? note});

  /// Edits an existing deposit.
  ResultFuture<DepositEntity> updateDeposit({required String id, required double amount, required DateTime date, String? note});

  /// Removes a deposit.
  ResultVoid deleteDeposit(String id);
}
