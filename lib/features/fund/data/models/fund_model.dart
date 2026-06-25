import 'package:clean_boilerplate/features/fund/domain/entities/fund_entity.dart';

/// Data-layer DTO for a single fund record.
class FundModel {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  const FundModel({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  FundModel copyWith({double? amount, DateTime? date, String? note}) {
    return FundModel(
      id: id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  FundEntity toEntity() =>
      FundEntity(id: id, amount: amount, date: date, note: note);
}
