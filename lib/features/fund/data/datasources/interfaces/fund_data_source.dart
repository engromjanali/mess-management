import 'package:clean_boilerplate/features/fund/data/models/fund_model.dart';

/// Contract for any source that can provide & mutate fund entries.
abstract class FundDataSource {
  Future<List<FundModel>> getAllFunds();

  Future<List<FundModel>> getFundsByDate(DateTime date);

  Future<List<FundModel>> getFundsInRange(DateTime start, DateTime end);

  Future<FundModel> addFund({
    required double amount,
    required DateTime date,
    String? note,
  });

  Future<FundModel> updateFund({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  });

  Future<void> deleteFund(String id);
}
