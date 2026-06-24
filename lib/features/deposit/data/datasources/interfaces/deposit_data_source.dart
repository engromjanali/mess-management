import '../../models/deposit_model.dart';

/// Contract for any source that can provide & mutate deposits.
abstract class DepositDataSource {
  Future<List<DepositMemberModel>> getMembers();

  Future<List<DepositModel>> getAllDeposits();

  Future<List<DepositModel>> getMemberDeposits(String memberId);

  Future<List<DepositModel>> getDepositsByDate(DateTime date);

  Future<List<DepositModel>> getDepositsInRange(DateTime start, DateTime end);

  Future<List<DepositModel>> getMyDeposits();

  Future<DepositModel> addDeposit({
    required String memberId,
    required double amount,
    required DateTime date,
    String? note,
  });

  Future<DepositModel> updateDeposit({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  });

  Future<void> deleteDeposit(String id);
}
