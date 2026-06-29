import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';

/// Data-layer DTO for a single line item.
class CostItemModel {
  final String product;
  final double price;

  const CostItemModel({required this.product, required this.price});

  CostItemEntity toEntity() => CostItemEntity(product: product, price: price);

  static CostItemModel fromEntity(CostItemEntity e) => CostItemModel(product: e.product, price: e.price);
}

/// Data-layer DTO for a selectable member.
class CostMemberModel {
  final String id;
  final String name;

  const CostMemberModel({required this.id, required this.name});

  CostMemberEntity toEntity() => CostMemberEntity(id: id, name: name);
}

/// Data-layer DTO for a bazar/cost entry.
class CostModel {
  final String id;
  final String personId;
  final String personName;
  final DateTime date;
  final List<CostItemModel> items;

  const CostModel({required this.id, required this.personId, required this.personName, required this.date, required this.items});

  CostModel copyWith({String? personId, String? personName, DateTime? date, List<CostItemModel>? items}) {
    return CostModel(id: id, personId: personId ?? this.personId, personName: personName ?? this.personName, date: date ?? this.date, items: items ?? this.items);
  }

  CostEntity toEntity() => CostEntity(id: id, personId: personId, personName: personName, date: date, items: items.map((i) => i.toEntity()).toList());
}
