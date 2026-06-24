import '../../domain/entities/fund_entity.dart';

/// Data-layer DTO for a single fund record.
class FundModel {
  final String id;
  final double amount;
  final DateTime date;

  const FundModel({
    required this.id,
    required this.amount,
    required this.date,
  });

  FundModel copyWith({double? amount, DateTime? date}) {
    return FundModel(
      id: id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  FundEntity toEntity() => FundEntity(id: id, amount: amount, date: date);
}
