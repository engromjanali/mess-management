import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/data/models/cost_model.dart';
import 'package:clean_boilerplate/features/cost/data/datasources/interfaces/cost_data_source.dart';

/// In-memory mock for the Cost/cost feature.
///
/// Holds a fixed roster of members and a flat list of Cost entries, each with
/// its own line items. Swap this binding for a remote implementation later —
/// the repository and presentation layers won't change.
@LazySingleton(as: CostDataSource)
class CostLocalDataSourceImpl implements CostDataSource {
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

  /// Session-mutable store of Cost entries, seeded with a few records.
  final List<CostModel> _costs = [
    CostModel(
      id: 'c1',
      personId: '1',
      personName: 'Romjan Ali',
      date: DateTime(2026, 6, 21, 16, 31),
      items: const [
        CostItemModel(product: 'Morgi', price: 350),
        CostItemModel(product: 'Prayag', price: 100),
      ],
    ),
    CostModel(
      id: 'c2',
      personId: '2',
      personName: 'Mehedi Hasan',
      date: DateTime(2026, 6, 20, 10, 15),
      items: const [
        CostItemModel(product: 'Rice', price: 700),
        CostItemModel(product: 'Oil', price: 220),
        CostItemModel(product: 'Onion', price: 150),
      ],
    ),
    CostModel(
      id: 'c3',
      personId: '4',
      personName: 'Tanvir Ahmed',
      date: DateTime(2026, 6, 18, 18, 5),
      items: const [
        CostItemModel(product: 'Fish', price: 620),
        CostItemModel(product: 'Vegetables', price: 180),
      ],
    ),
  ];

  /// Monotonic counter for generating new ids within the session.
  int _seq = 100;

  String _nextId() => 'c${_seq++}';

  String _nameFor(String personId) => _roster.firstWhere((m) => m.id == personId).name;

  List<CostModel> _sorted(Iterable<CostModel> items) {
    final list = items.toList()..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<CostItemModel> _toModels(List<CostItemEntity> items) => items.map(CostItemModel.fromEntity).toList();

  @override
  Future<List<CostMemberModel>> getMembers() async {
    return _roster.map((m) => CostMemberModel(id: m.id, name: m.name)).toList();
  }

  @override
  Future<List<CostModel>> getCosts() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _sorted(_costs);
  }

  @override
  Future<CostModel> addCost({required String personId, required DateTime date, required List<CostItemEntity> items}) async {
    if (!_roster.any((m) => m.id == personId)) {
      throw ServerException(message: 'Unknown member');
    }
    final model = CostModel(id: _nextId(), personId: personId, personName: _nameFor(personId), date: date, items: _toModels(items));
    _costs.add(model);
    return model;
  }

  @override
  Future<CostModel> updateCost({required String id, required String personId, required DateTime date, required List<CostItemEntity> items}) async {
    final index = _costs.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw ServerException(message: 'Cost entry not found');
    }
    if (!_roster.any((m) => m.id == personId)) {
      throw ServerException(message: 'Unknown member');
    }
    final updated = _costs[index].copyWith(personId: personId, personName: _nameFor(personId), date: date, items: _toModels(items));
    _costs[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCost(String id) async {
    _costs.removeWhere((c) => c.id == id);
  }
}
