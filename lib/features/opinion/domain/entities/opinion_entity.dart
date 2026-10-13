import 'package:equatable/equatable.dart';

enum OpinionVisibility { realtime, afterPublish }

class OpinionPeriodEntity extends Equatable {
  const OpinionPeriodEntity({required this.id, required this.messId, required this.title, required this.details, required this.startDate, required this.endDate, this.acceptingMessages = true, this.visibility = OpinionVisibility.afterPublish, this.seasonId = '', this.seasonName = '', this.canWrite = false, this.opinionCount = 0, this.hasMoreOpinions = false, this.opinions = const []});

  final String id;
  final String messId;
  final String title;
  final String details;
  final DateTime startDate;
  final DateTime endDate;
  final bool acceptingMessages;
  final OpinionVisibility visibility;
  final String seasonId;
  final String seasonName;
  final bool canWrite;
  final int opinionCount;
  final bool hasMoreOpinions;
  final List<AnonymousOpinionEntity> opinions;

  OpinionPeriodEntity copyWith({DateTime? endDate, bool? acceptingMessages, OpinionVisibility? visibility}) => OpinionPeriodEntity(
    id: id,
    messId: messId,
    title: title,
    details: details,
    startDate: startDate,
    endDate: endDate ?? this.endDate,
    acceptingMessages: acceptingMessages ?? this.acceptingMessages,
    visibility: visibility ?? this.visibility,
    seasonId: seasonId,
    seasonName: seasonName,
    canWrite: canWrite,
    opinionCount: opinionCount,
    hasMoreOpinions: hasMoreOpinions,
    opinions: opinions,
  );

  bool isWithinDateRangeAt(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool isActiveAt(DateTime value) => acceptingMessages && isWithinDateRangeAt(value);

  @override
  List<Object?> get props => [id, messId, title, details, startDate, endDate, acceptingMessages, visibility, seasonId, seasonName, canWrite, opinionCount, hasMoreOpinions, opinions];
}

class AnonymousOpinionEntity extends Equatable {
  const AnonymousOpinionEntity({required this.id, required this.periodId, required this.message, required this.createdAt, this.isPublished = false});

  final String id;
  final String periodId;
  final String message;
  final DateTime createdAt;
  final bool isPublished;

  AnonymousOpinionEntity copyWith({bool? isPublished}) => AnonymousOpinionEntity(id: id, periodId: periodId, message: message, createdAt: createdAt, isPublished: isPublished ?? this.isPublished);

  @override
  List<Object?> get props => [id, periodId, message, createdAt, isPublished];
}
