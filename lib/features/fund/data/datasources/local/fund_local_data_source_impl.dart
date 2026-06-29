import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/features/fund/data/models/fund_model.dart';
import 'package:clean_boilerplate/features/fund/data/datasources/interfaces/fund_data_source.dart';

/// In-memory mock for the fund feature.
///
/// Holds a flat list of shared fund records (no member). Entries keep their
/// sign (positive → credit, negative → debit) and carry an optional note.
/// Swap this binding for a remote implementation later — the repository and
/// presentation layers won't change.
@LazySingleton(as: FundDataSource)
class FundLocalDataSourceImpl implements FundDataSource {
  /// Session-mutable store of funds, seeded with a few sample records.
  final List<FundModel> _funds = [
    FundModel(id: 'f1', amount: 5000, date: DateTime(2026, 6, 2), note: 'Monthly contribution'),
    FundModel(id: 'f2', amount: -1200, date: DateTime(2026, 6, 8), note: 'Gas bill'),
    FundModel(id: 'f3', amount: 3000, date: DateTime(2026, 6, 8)),
    FundModel(id: 'f4', amount: -750, date: DateTime(2026, 6, 15), note: 'Repairs'),
  ];

  /// Monotonic counter for generating new ids within the session.
  int _seq = 100;

  String _nextId() => 'f${_seq++}';

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Newest-first ordering shared by every list query.
  List<FundModel> _sorted(Iterable<FundModel> items) {
    final list = items.toList()..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<FundModel>> getAllFunds() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_funds);
  }

  @override
  Future<List<FundModel>> getFundsByDate(DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_funds.where((f) => _sameDay(f.date, date)));
  }

  @override
  Future<List<FundModel>> getFundsInRange(DateTime start, DateTime end) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Normalise to inclusive day bounds regardless of the time component.
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _sorted(_funds.where((f) => !f.date.isBefore(from) && !f.date.isAfter(to)));
  }

  @override
  Future<FundModel> addFund({required double amount, required DateTime date, String? note}) async {
    final model = FundModel(id: _nextId(), amount: amount, date: DateTime(date.year, date.month, date.day), note: note);
    _funds.add(model);
    return model;
  }

  @override
  Future<FundModel> updateFund({required String id, required double amount, required DateTime date, String? note}) async {
    final index = _funds.indexWhere((f) => f.id == id);
    if (index == -1) {
      throw ServerException(message: 'Fund entry not found');
    }
    // Rebuild directly so a cleared note (null) is honoured.
    final updated = FundModel(id: id, amount: amount, date: DateTime(date.year, date.month, date.day), note: note);
    _funds[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteFund(String id) async {
    _funds.removeWhere((f) => f.id == id);
  }
}
