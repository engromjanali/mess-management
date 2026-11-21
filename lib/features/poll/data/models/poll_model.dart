import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

/// Data-layer DTO for a poll / option.
class PollModel {
  const PollModel({
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
  final DateTime pollDate;
  final DateTime closesAt;
  final PollStatus status;
  final bool allowMultiple;
  final int maxChoices;
  final bool isAnonymous;
  final PollResultsVisibility resultsVisibility;
  final List<PollOptionModel> options;
  final List<String> myOptionIds;
  final bool hasVoted;
  final int totalVotes;
  final int eligibleMemberCount;
  final bool canVote;
  final bool resultsVisible;
  final bool canManage;
  final bool hasVotes;
  final bool canEditOptions;

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: '${json['id']}',
      seasonId: '${json['season_id']}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pollDate: DateTime.parse(json['poll_date'] as String),
      closesAt: DateTime.parse(json['closes_at'] as String).toLocal(),
      status: switch (json['status']) {
        'closed' => PollStatus.closed,
        'cancelled' => PollStatus.cancelled,
        _ => PollStatus.open,
      },
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      maxChoices: (json['max_choices'] as num?)?.toInt() ?? 1,
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      resultsVisibility: switch (json['results_visibility']) {
        'always' => PollResultsVisibility.always,
        'after_close' => PollResultsVisibility.afterClose,
        _ => PollResultsVisibility.afterVote,
      },
      options: (json['options'] as List<dynamic>? ?? [])
          .map((item) => PollOptionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      myOptionIds: (json['my_option_ids'] as List<dynamic>? ?? []).map((id) => '$id').toList(),
      hasVoted: json['has_voted'] as bool? ?? false,
      totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      eligibleMemberCount: (json['eligible_member_count'] as num?)?.toInt() ?? 0,
      canVote: json['can_vote'] as bool? ?? false,
      resultsVisible: json['results_visible'] as bool? ?? false,
      canManage: json['can_manage'] as bool? ?? false,
      hasVotes: json['has_votes'] as bool? ?? false,
      canEditOptions: json['can_edit_options'] as bool? ?? false,
    );
  }

  PollEntity toEntity() => PollEntity(
        id: id,
        seasonId: seasonId,
        title: title,
        description: description,
        pollDate: pollDate,
        closesAt: closesAt,
        status: status,
        allowMultiple: allowMultiple,
        maxChoices: maxChoices,
        isAnonymous: isAnonymous,
        resultsVisibility: resultsVisibility,
        options: options.map((option) => option.toEntity()).toList(),
        myOptionIds: myOptionIds,
        hasVoted: hasVoted,
        totalVotes: totalVotes,
        eligibleMemberCount: eligibleMemberCount,
        canVote: canVote,
        resultsVisible: resultsVisible,
        canManage: canManage,
        hasVotes: hasVotes,
        canEditOptions: canEditOptions,
      );
}

class PollOverviewModel {
  const PollOverviewModel({required this.polls, required this.canManage, this.nextPage});

  final List<PollModel> polls;
  final bool canManage;
  final int? nextPage;

  factory PollOverviewModel.fromJson(Map<String, dynamic> json) {
    return PollOverviewModel(
      polls: (json['data'] as List<dynamic>? ?? [])
          .map((item) => PollModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      canManage: json['can_manage'] as bool? ?? false,
      nextPage: (json['next_page'] as num?)?.toInt(),
    );
  }

  PollOverviewEntity toEntity() => PollOverviewEntity(
        polls: polls.map((poll) => poll.toEntity()).toList(),
        canManage: canManage,
        nextPage: nextPage,
      );
}

class PollOptionModel {
  const PollOptionModel({required this.id, required this.text, this.voteCount});

  final String id;
  final String text;
  final int? voteCount;

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: '${json['id']}',
      text: json['text'] as String? ?? '',
      voteCount: (json['vote_count'] as num?)?.toInt(),
    );
  }

  PollOptionEntity toEntity() => PollOptionEntity(id: id, text: text, voteCount: voteCount);
}
