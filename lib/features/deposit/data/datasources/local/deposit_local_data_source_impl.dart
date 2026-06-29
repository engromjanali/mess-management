import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/features/deposit/data/models/deposit_model.dart';
import 'package:clean_boilerplate/features/deposit/data/datasources/interfaces/deposit_data_source.dart';

/// In-memory mock for the deposit feature.
///
/// Holds a fixed roster of members and a flat list of deposit records.
/// Deposits are recorded one member at a time and keep their sign
/// (positive → credit, negative → debit). Swap this binding for a remote
/// implementation later — the repository and presentation layers won't change.
@LazySingleton(as: DepositDataSource)
class DepositLocalDataSourceImpl implements DepositDataSource {
  /// The member whose deposits a non-admin "user" is allowed to see.
  static const String _currentUserId = '1';

  /// Fixed roster (mirrors the dashboard / meal-entry members).
  static const List<({String id, String name})> _roster = [
    (id: '1', name: 'Romjan Ali'),
    (id: '2', name: 'Mehedi Hasan'),
    (id: '3', name: 'Sakib Khan'),
    (id: '4', name: 'Tanvir Ahmed'),
    (id: '5', name: 'Rakib Hossain'),
    (id: '6', name: 'Jisan Mahmud'),
    (id: '7', name: 'Nayeem Islam'),
  ];

  /// Session-mutable store of deposits, seeded with a few sample records.
  final List<DepositModel> _deposits = [
    DepositModel(id: 'd1', memberId: '1', memberName: 'Romjan Ali', amount: 2000, date: DateTime(2026, 6), note: 'Monthly deposit'),
    DepositModel(id: 'd2', memberId: '2', memberName: 'Mehedi Hasan', amount: 1500, date: DateTime(2026, 6), note: 'Monthly deposit'),
    DepositModel(id: 'd3', memberId: '1', memberName: 'Romjan Ali', amount: -300, date: DateTime(2026, 6, 10), note: 'Refund adjustment'),
    DepositModel(id: 'd4', memberId: '3', memberName: 'Sakib Khan', amount: 2500, date: DateTime(2026, 6, 10)),
  ];

  /// Monotonic counter for generating new ids within the session.
  int _seq = 100;

  String _nextId() => 'd${_seq++}';

  String _nameFor(String memberId) => _roster.firstWhere((m) => m.id == memberId).name;

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Newest-first ordering shared by every list query.
  List<DepositModel> _sorted(Iterable<DepositModel> items) {
    final list = items.toList()..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<DepositMemberModel>> getMembers() async {
    return _roster.map((m) => DepositMemberModel(id: m.id, name: m.name)).toList();
  }

  @override
  Future<List<DepositModel>> getAllDeposits() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_deposits);
  }

  @override
  Future<List<DepositModel>> getMemberDeposits(String memberId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_deposits.where((d) => d.memberId == memberId));
  }

  @override
  Future<List<DepositModel>> getDepositsByDate(DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_deposits.where((d) => _sameDay(d.date, date)));
  }

  @override
  Future<List<DepositModel>> getDepositsInRange(DateTime start, DateTime end) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Normalise to inclusive day bounds regardless of the time component.
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _sorted(_deposits.where((d) => !d.date.isBefore(from) && !d.date.isAfter(to)));
  }

  @override
  Future<List<DepositModel>> getMyDeposits() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_deposits.where((d) => d.memberId == _currentUserId));
  }

  @override
  Future<DepositModel> addDeposit({required String memberId, required double amount, required DateTime date, String? note}) async {
    if (!_roster.any((m) => m.id == memberId)) {
      throw ServerException(message: 'Unknown member');
    }
    final model = DepositModel(id: _nextId(), memberId: memberId, memberName: _nameFor(memberId), amount: amount, date: DateTime(date.year, date.month, date.day), note: note);
    _deposits.add(model);
    return model;
  }

  @override
  Future<DepositModel> updateDeposit({required String id, required double amount, required DateTime date, String? note}) async {
    final index = _deposits.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ServerException(message: 'Deposit not found');
    }
    final updated = _deposits[index].copyWith(amount: amount, date: DateTime(date.year, date.month, date.day), note: note);
    _deposits[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteDeposit(String id) async {
    _deposits.removeWhere((d) => d.id == id);
  }
}
