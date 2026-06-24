import 'package:equatable/equatable.dart';

/// A single line item within a bazar/cost entry — one product and its price.
class CostItemEntity extends Equatable {
  final String product;
  final double price;

  const CostItemEntity({required this.product, required this.price});

  @override
  List<Object?> get props => [product, price];
}

/// A member a bazar/cost entry can be recorded against.
class CostMemberEntity extends Equatable {
  final String id;
  final String name;

  const CostMemberEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// One bazar/cost entry: who did the shopping, when, and the list of products
/// bought with their prices. The [total] is the sum of every line item.
class CostEntity extends Equatable {
  final String id;
  final String personId;
  final String personName;
  final DateTime date;
  final List<CostItemEntity> items;

  const CostEntity({
    required this.id,
    required this.personId,
    required this.personName,
    required this.date,
    required this.items,
  });

  /// Sum of every line item's price.
  double get total => items.fold<double>(0, (sum, i) => sum + i.price);

  int get itemCount => items.length;

  @override
  List<Object?> get props => [id, personId, personName, date, items];
}

/// Aggregate helpers over a list of cost entries (used for summary cards).
extension CostListX on List<CostEntity> {
  /// Grand total across every entry.
  double get grandTotal => fold<double>(0, (sum, c) => sum + c.total);

  /// Total number of line items across every entry.
  int get totalItems => fold<int>(0, (sum, c) => sum + c.itemCount);
}
