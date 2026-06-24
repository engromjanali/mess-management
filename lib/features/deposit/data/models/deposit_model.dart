import '../../domain/entities/deposit_entity.dart';

/// Data-layer DTO for a selectable member.
class DepositMemberModel {
  final String id;
  final String name;

  const DepositMemberModel({required this.id, required this.name});

  DepositMemberEntity toEntity() => DepositMemberEntity(id: id, name: name);
}

/// Data-layer DTO for a single deposit record.
class DepositModel {
  final String id;
  final String memberId;
  final String memberName;
  final double amount;
  final DateTime date;
  final String? note;

  const DepositModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.date,
    this.note,
  });

  DepositModel copyWith({
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return DepositModel(
      id: id,
      memberId: memberId,
      memberName: memberName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  DepositEntity toEntity() => DepositEntity(
        id: id,
        memberId: memberId,
        memberName: memberName,
        amount: amount,
        date: date,
        note: note,
      );
}
