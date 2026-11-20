import 'package:flutter_test/flutter_test.dart';
import 'package:mess_pilot/features/poll/data/models/poll_model.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

void main() {
  Map<String, dynamic> pollJson({Map<String, dynamic> overrides = const {}}) => {
        'id': 7,
        'season_id': 3,
        'title': 'Friday lunch',
        'description': 'Choose the menu',
        'poll_date': '2026-11-20',
        'closes_at': '2026-11-20T17:59:59Z',
        'status': 'open',
        'allow_multiple': true,
        'max_choices': 2,
        'is_anonymous': false,
        'results_visibility': 'after_close',
        'options': [
          {'id': 1, 'text': 'Beef', 'vote_count': 4},
          {'id': 2, 'text': 'Fish', 'vote_count': null},
        ],
        'my_option_ids': [1],
        'has_voted': true,
        'total_votes': 5,
        'eligible_member_count': 8,
        'can_vote': true,
        'results_visible': false,
        'can_manage': true,
        'has_votes': true,
        'can_edit_options': false,
        ...overrides,
      };

  group('PollModel', () {
    test('parses the full payload into a poll entity', () {
      final poll = PollModel.fromJson(pollJson()).toEntity();

      expect(poll.id, '7');
      expect(poll.seasonId, '3');
      expect(poll.title, 'Friday lunch');
      expect(poll.pollDate, DateTime(2026, 11, 20));
      expect(poll.status, PollStatus.open);
      expect(poll.allowMultiple, isTrue);
      expect(poll.maxChoices, 2);
      expect(poll.isAnonymous, isFalse);
      expect(poll.resultsVisibility, PollResultsVisibility.afterClose);
      expect(poll.options.map((option) => option.text), ['Beef', 'Fish']);
      expect(poll.options.first.voteCount, 4);
      expect(poll.myOptionIds, ['1']);
      expect(poll.hasVoted, isTrue);
      expect(poll.totalVotes, 5);
      expect(poll.eligibleMemberCount, 8);
      expect(poll.canVote, isTrue);
      expect(poll.resultsVisible, isFalse);
      expect(poll.canManage, isTrue);
      expect(poll.hasVotes, isTrue);
      expect(poll.canEditOptions, isFalse);
      expect(poll.isOpen, isTrue);
    });

    test('falls back for unknown status and results visibility', () {
      final poll = PollModel.fromJson(pollJson(overrides: {'status': 'archived', 'results_visibility': 'never'})).toEntity();

      expect(poll.status, PollStatus.open);
      expect(poll.resultsVisibility, PollResultsVisibility.afterVote);
    });

    test('maps closed and cancelled statuses', () {
      expect(PollModel.fromJson(pollJson(overrides: {'status': 'closed'})).toEntity().status, PollStatus.closed);
      expect(PollModel.fromJson(pollJson(overrides: {'status': 'cancelled'})).toEntity().status, PollStatus.cancelled);
    });

    test('compares days and computes participation', () {
      final poll = PollModel.fromJson(pollJson()).toEntity();

      expect(poll.isSameDay(DateTime(2026, 11, 20, 23, 59)), isTrue);
      expect(poll.isSameDay(DateTime(2026, 11, 21)), isFalse);
      expect(poll.participation, closeTo(5 / 8, 0.0001));
      expect(PollModel.fromJson(pollJson(overrides: {'eligible_member_count': 0})).toEntity().participation, 0);
    });
  });

  group('PollOverviewModel', () {
    test('parses the paginated list envelope', () {
      final overview = PollOverviewModel.fromJson({
        'can_manage': true,
        'next_page': 2,
        'data': [pollJson()],
      }).toEntity();

      expect(overview.polls, hasLength(1));
      expect(overview.polls.single.title, 'Friday lunch');
      expect(overview.canManage, isTrue);
      expect(overview.nextPage, 2);
    });

    test('treats a missing list as empty', () {
      final overview = PollOverviewModel.fromJson(const {}).toEntity();

      expect(overview.polls, isEmpty);
      expect(overview.canManage, isFalse);
      expect(overview.nextPage, isNull);
    });
  });
}
