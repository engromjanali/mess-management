import 'package:equatable/equatable.dart';

class OpinionPeriodEntity extends Equatable {
  const OpinionPeriodEntity({required this.id, required this.messId, required this.title, required this.details, required this.startDate, required this.endDate, this.acceptingMessages = true});

  final String id;
  final String messId;
  final String title;
  final String details;
  final DateTime startDate;
  final DateTime endDate;
  final bool acceptingMessages;

  OpinionPeriodEntity copyWith({DateTime? endDate, bool? acceptingMessages}) => OpinionPeriodEntity(
    id: id,
    messId: messId,
    title: title,
    details: details,
    startDate: startDate,
    endDate: endDate ?? this.endDate,
    acceptingMessages: acceptingMessages ?? this.acceptingMessages,
  );

  bool isWithinDateRangeAt(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool isActiveAt(DateTime value) => acceptingMessages && isWithinDateRangeAt(value);

  @override
  List<Object?> get props => [id, messId, title, details, startDate, endDate, acceptingMessages];
}

class AnonymousOpinionEntity extends Equatable {
  const AnonymousOpinionEntity({required this.id, required this.periodId, required this.message, required this.createdAt});

  final String id;
  final String periodId;
  final String message;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, periodId, message, createdAt];
}
