import 'package:equatable/equatable.dart';

enum PollStatus { open, closed, cancelled }

enum PollResultsVisibility { always, afterVote, afterClose }

/// One answer a member can choose.
class PollOptionEntity extends Equatable {
  const PollOptionEntity({required this.id, required this.text, this.voteCount});

  final String id;
  final String text;

  /// Null while the results are hidden from this member.
  final int? voteCount;

  @override
  List<Object?> get props => [id, text, voteCount];
}

/// A dated question in the current season.
class PollEntity extends Equatable {
  const PollEntity({
    required this.id,
    required this.seasonId,
    required this.title,
    required this.description,
    required this.pollDate,
    required this.closesAt,
    required this.status,
    required this.allowMultiple,
    required this.maxChoices,
    required this.isAnonymous,
    required this.resultsVisibility,
    required this.options,
    required this.myOptionIds,
    required this.hasVoted,
    required this.totalVotes,
    required this.eligibleMemberCount,
    required this.canVote,
    required this.resultsVisible,
    required this.canManage,
    required this.hasVotes,
    required this.canEditOptions,
  });

  final String id;
  final String seasonId;
  final String title;
  final String description;

  /// The day this poll belongs to (date only).
  final DateTime pollDate;

  /// Voting deadline.
  final DateTime closesAt;
  final PollStatus status;
  final bool allowMultiple;
  final int maxChoices;
  final bool isAnonymous;
  final PollResultsVisibility resultsVisibility;
  final List<PollOptionEntity> options;
  final List<String> myOptionIds;
  final bool hasVoted;
  final int totalVotes;
  final int eligibleMemberCount;
  final bool canVote;
  final bool resultsVisible;
  final bool canManage;
  final bool hasVotes;
  final bool canEditOptions;

  bool get isOpen => status == PollStatus.open;
  bool get isPast => !isOpen;

  bool isSameDay(DateTime value) =>
      pollDate.year == value.year && pollDate.month == value.month && pollDate.day == value.day;

  double get participation => eligibleMemberCount == 0 ? 0 : totalVotes / eligibleMemberCount;

  @override
  List<Object?> get props => [
        id,
        seasonId,
        title,
        description,
        pollDate,
        closesAt,
        status,
        allowMultiple,
        maxChoices,
        isAnonymous,
        resultsVisibility,
        options,
        myOptionIds,
        hasVoted,
        totalVotes,
        eligibleMemberCount,
        canVote,
        resultsVisible,
        canManage,
        hasVotes,
        canEditOptions,
      ];
}

/// A page of polls plus the manager flag.
class PollOverviewEntity extends Equatable {
  const PollOverviewEntity({required this.polls, required this.canManage, this.nextPage});

  final List<PollEntity> polls;
  final bool canManage;
  final int? nextPage;

  @override
  List<Object?> get props => [polls, canManage, nextPage];
}

/// The values needed to create or edit a poll.
class PollDraft extends Equatable {
  const PollDraft({
    required this.title,
    required this.description,
    required this.pollDate,
    required this.options,
    this.allowMultiple = false,
    this.maxChoices = 1,
    this.isAnonymous = true,
    this.resultsVisibility = PollResultsVisibility.afterVote,
  });

  final String title;
  final String description;
  final DateTime pollDate;
  final List<String> options;
  final bool allowMultiple;
  final int maxChoices;
  final bool isAnonymous;
  final PollResultsVisibility resultsVisibility;

  @override
  List<Object?> get props => [title, description, pollDate, options, allowMultiple, maxChoices, isAnonymous, resultsVisibility];
}
