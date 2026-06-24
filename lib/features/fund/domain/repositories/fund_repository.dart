import '../../../../config/util/result.dart';
import '../entities/fund_entity.dart';

/// Fund repository contract (abstraction in the domain layer).
abstract class FundRepository {
  /// Every fund entry across all dates (newest first).
  ResultFuture<List<FundEntity>> getAllFunds();

  /// All fund entries on a single [date] (newest first).
  ResultFuture<List<FundEntity>> getFundsByDate(DateTime date);

  /// All fund entries within an inclusive [start]–[end] range.
  ResultFuture<List<FundEntity>> getFundsInRange(DateTime start, DateTime end);

  /// Records a fund entry.
  ///
  /// [amount] keeps its sign — positive for a credit, negative for a debit.
  ResultFuture<FundEntity> addFund({
    required double amount,
    required DateTime date,
    String? note,
  });

  /// Edits an existing fund entry.
  ResultFuture<FundEntity> updateFund({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  });

  /// Removes a fund entry.
  ResultVoid deleteFund(String id);
}
